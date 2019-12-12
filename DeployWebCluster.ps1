$GitBasePath = '/Users/billy/workspace/dev/demos/AzureWordPressCluster'

New-AzResourceGroupDeployment -ResourceGroupName  WordPressClusterGroup `
    -TemplateFile "$GitBasePath/azuredeploy.json" `
    -TemplateParameterFile "$GitBasePath/azuredeploy.parameters.json"