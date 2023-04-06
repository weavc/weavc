---
layout: post
title: Custom lifetime validator for long lived JWT in dotnet
tags: ['dev', 'security']
terms: ['dev', 'dotnet']
icon: code-slash
---

Workaround for: [AzureAD/azure-activedirectory-identitymodel-extensions-for-dotnet/issues/92](https://github.com/AzureAD/azure-activedirectory-identitymodel-extensions-for-dotnet/issues/92)

There is currently an issue with the default lifetime validation for a token, where if the token expires after `19/01/2038 12:00:00 AM` it overflows the `int` value causing the `DateTime` recieved by the default `LifetimeValidatier` to be `null`.

The following is a custom `LifetimeValidator` method that can be used in `TokenValidationParameters`. It resolves the issue by wrapping the default `LifetimeValidator` provided in `Microsoft.IdentityModel.Tokens` and using the `ValidTo` property on the Security Token passed to the method if the criteria is met.

```c#
    public bool CustomLifetimeValidator(
        DateTime? notBefore, 
        DateTime? expires, 
        SecurityToken securityToken, 
        TokenValidationParameters validationParameters)
    {
        if (!expires.HasValue && validationParameters.RequireExpirationTime)
        {
            var overflowDate = DateTimeOffset.FromUnixTimeSeconds(int.MaxValue).DateTime;
            if (securityToken is not null && securityToken.ValidTo >= overflowDate)
                expires = securityToken.ValidTo;
        }
        
        // Prevents validation loop
        var newParameters = validationParameters.Clone();
        newParameters.LifetimeValidator = null;
        
        // Use the default validation logic with the new expiry time
        Validators.ValidateLifetime(notBefore, expires, securityToken, newParameters);

        return true;
    }
```
