# Manual deployment.

az deployment sub create `
--location 'UkSouth' `
--template-file "C:\Users\chiad.WHITEHOUSE\r_app\deploy\bicep\main.bicep" `
--parameters "C:\Users\chiad.WHITEHOUSE\r_app\deploy\bicep\main.dev.bicepparam" `
--debug