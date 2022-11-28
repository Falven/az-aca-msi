using System.CommandLine;
using Azure.Identity;
using Azure.Security.KeyVault.Secrets;

var secretShowVersionOption = new Option<string>(
    name: "--version",
    description: "The secret version. If omitted, uses the latest version."
);
var secretShowVaultNameOption = new Option<string>(
    name: "--vault-name",
    description: "Name of the Key Vault. Required if --id is not specified."
);
var secretShowNameOption = new Option<string>(
    name: "--name",
    description: "Name of the secret. Required if --id is not specified."
);
var secretShowIdOption = new Option<string>(
    name: "--id",
    description: "Id of the secret. If specified all other 'Id' arguments should be omitted."
);
var secretShowCommand = new Command("show", @$"Get a specified secret from a given key vault.
{Environment.NewLine}{Environment.NewLine}
The GET operation is applicable to any secret stored in Azure Key Vault.
This operation requires the secrets/get permission.")
{
    secretShowVersionOption,
    secretShowVaultNameOption,
    secretShowNameOption,
    secretShowIdOption
};
var secretCommand = new Command("secret", "Manage secrets.") { secretShowCommand };
var rootCommand = new RootCommand("KeyVault CLI.") { secretCommand };

const string mutuallyExclusiveArgumentsMessage = "--id and --name/--vault-name are mutually exclusive arguments.";

secretShowIdOption.AddValidator(optionResult =>
{
    var secretShowVaultNameOptionResult = optionResult.FindResultFor(secretShowVaultNameOption);
    var secretShowNameOptionResult = optionResult.FindResultFor(secretShowNameOption);
    if (secretShowVaultNameOptionResult is not null || secretShowNameOptionResult is not null)
    {
        optionResult.ErrorMessage = mutuallyExclusiveArgumentsMessage;
    }
});

secretShowNameOption.AddValidator(optionResult =>
{
    var secretShowIdOptionResult = optionResult.FindResultFor(secretShowIdOption);
    if (secretShowIdOptionResult is not null)
    {
        optionResult.ErrorMessage = mutuallyExclusiveArgumentsMessage;
        return;
    }

    var secretShowVaultNameOptionResult = optionResult.FindResultFor(secretShowVaultNameOption);
    if (secretShowVaultNameOptionResult is null)
    {
        optionResult.ErrorMessage = "--vault-name is required.";
    }
});

secretShowVaultNameOption.AddValidator(optionResult =>
{
    var secretShowIdOptionResult = optionResult.FindResultFor(secretShowIdOption);
    if (secretShowIdOptionResult is not null)
    {
        optionResult.ErrorMessage = mutuallyExclusiveArgumentsMessage;
        return;
    }

    var secretShowNameOptionResult = optionResult.FindResultFor(secretShowNameOption);
    if (secretShowNameOptionResult is null)
    {
        optionResult.ErrorMessage = "--name is required.";
    }
});

secretShowCommand.SetHandler(
    async (secretIdValue, secretNameValue, secretVaultNameValue, secretVersionValue) =>
        {
            Uri keyVaultUri;
            if (secretIdValue != null)
            {
                var secretIdUri = new Uri(secretIdValue);
                keyVaultUri = new Uri(secretIdUri.GetLeftPart(UriPartial.Authority));
                var secretsIndex = Array.IndexOf(secretIdUri.Segments, "secrets/");
                secretNameValue = secretIdUri.Segments[secretsIndex + 1].Replace("/", "");
            }
            else
            {
                keyVaultUri = new Uri($"https://{secretVaultNameValue}.vault.azure.net/");
            }
            var client = new SecretClient(keyVaultUri, new DefaultAzureCredential());
            var result = await client.GetSecretAsync(secretNameValue, secretVersionValue);
            Console.WriteLine(result.Value.Value);
        },
    secretShowIdOption, secretShowNameOption, secretShowVaultNameOption, secretShowVersionOption
);

return await rootCommand.InvokeAsync(args);