# onecommerce-infrastructure

[![Build](https://github.com/Arthure-code/onecommerce-infrastructure/actions/workflows/build.yml/badge.svg)](https://github.com/Arthure-code/onecommerce-infrastructure/actions/workflows/build.yml)
[![Quality gate](https://sonarcloud.io/api/project_badges/measure?project=Arthure-code_onecommerce-infrastructure&metric=alert_status)](https://sonarcloud.io/summary/new_code?id=Arthure-code_onecommerce-infrastructure)
[![Bugs](https://sonarcloud.io/api/project_badges/measure?project=Arthure-code_onecommerce-infrastructure&metric=bugs)](https://sonarcloud.io/summary/new_code?id=Arthure-code_onecommerce-infrastructure)
[![Vulnerabilities](https://sonarcloud.io/api/project_badges/measure?project=Arthure-code_onecommerce-infrastructure&metric=vulnerabilities)](https://sonarcloud.io/summary/new_code?id=Arthure-code_onecommerce-infrastructure)
[![Security rating](https://sonarcloud.io/api/project_badges/measure?project=Arthure-code_onecommerce-infrastructure&metric=security_rating)](https://sonarcloud.io/summary/new_code?id=Arthure-code_onecommerce-infrastructure)
[![Code smells](https://sonarcloud.io/api/project_badges/measure?project=Arthure-code_onecommerce-infrastructure&metric=code_smells)](https://sonarcloud.io/summary/new_code?id=Arthure-code_onecommerce-infrastructure)
[![Duplicated lines](https://sonarcloud.io/api/project_badges/measure?project=Arthure-code_onecommerce-infrastructure&metric=duplicated_lines_density)](https://sonarcloud.io/summary/new_code?id=Arthure-code_onecommerce-infrastructure)

Everything a five-service shop runs on, written once and deployed with one command: two App Service plans and their applications, a SQL server whose three databases share an elastic pool, and a storage account with a private container and a queue.

Bicep, Azure Resource Manager, Azure CLI.

## Screenshots

**What one deployment creates**

![The Bicep visualizer in Visual Studio Code: three groups, one per module. On the left the storage account with its blob service, its images container, its queue service and its orders queue. In the middle the SQL server, its firewall rule, its elastic pool and the databases module. On the right the App Service plan with its applications, their staging slot and the autoscale rule](docs/visualiseur.png)

## How it works

**Adding an application is one line.** The plans and what sits on them are a list at the top of `main.bicep`, and the App Service module is called once per entry. A sixth application joins a plan by being named; nothing else in the deployment has to hear about it.

**The environment decides what exists, not a comment.** `Dev` runs on F1, `Test` on B1, `Prod` on S1. The staging slot and the autoscale rule are written once and conditioned on the tier that carries them, because asking a free plan for a slot fails the deployment rather than being ignored.

**Names survive a second run.** The four random characters each application carries come from `uniqueString` seeded with the resource group, not from the clock. Deploying twice gives the same five applications instead of five more.

**The pool is Standard, and that is the only answer that holds.** The brief asks for the basic tier with 50 DTU minimum and 200 maximum per database. A Basic pool stops at 5 DTU per database, so the three numbers contradict each other; Standard is the cheapest tier where 50 and 200 exist, and the template says so where it sets them.

**Nothing answers in plain text.** The applications and their slots refuse HTTP, ask for TLS 1.2 and turn FTPS off. The storage account refuses HTTP and public blob access. The SQL server asks for TLS 1.2 and lets through a single address range.

**The linter is turned up and the templates pass it.** `bicepconfig.json` makes unused parameters, hand-built resource identifiers, missing parent properties, string concatenation where interpolation belongs and stale API versions errors rather than suggestions. `bicep build` reports nothing on the five files.

## Running it

The password is never written down. It is read from the environment when the parameters are compiled.

```bash
export SQL_ADMIN_PASSWORD='the password'
az deployment group what-if --resource-group rg-onecommerce --template-file main.bicep --parameters main.bicepparam
```

```bash
az deployment group create --resource-group rg-onecommerce --template-file main.bicep --parameters main.bicepparam
```

```bash
az bicep build --file main.bicep
```

## Résumé

Infrastructure Azure d'une boutique à cinq services, décrite en Bicep et déployée en une commande. Un modèle d'entrée appelle trois modules : les plans App Service et les applications qui les partagent, le serveur SQL avec son pool élastique et ses trois bases, et le compte de stockage avec son conteneur privé et sa file. Les plans et leurs applications tiennent dans une liste : ajouter une sixième application est une ligne, et rien d'autre dans le déploiement n'a besoin de le savoir. Le niveau d'environnement décide du palier tarifaire, F1 en développement, B1 en test, S1 en production, et c'est lui seul qui fait exister le slot de préproduction et la règle d'auto-scale, parce qu'un plan gratuit ne les accepte pas. Les quatre caractères aléatoires de chaque nom viennent du groupe de ressources et non de l'horloge, donc un second déploiement redonne les mêmes applications. Le pool est Standard et le modèle explique pourquoi : le niveau de base plafonne à 5 DTU par base, ce qui rend les 50 et 200 demandés impossibles. Rien ne répond en clair, et le linter est réglé en mode strict sur des règles qui sont des erreurs, pas des suggestions.

## Licence

MIT. See [LICENSE](LICENSE).
