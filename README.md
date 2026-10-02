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

![The resource group drawn with the official Azure icons: on the left two App Service plans, the first carrying the shop and the product API, the second carrying the file, order and loyalty APIs, with the autoscale rule below them; in the middle the SQL server, its single allowed address range and its elastic pool holding three databases; on the right the storage account with its private images container and its order queue](docs/architecture.png)

The diagram is a draw.io file, [docs/architecture.drawio](docs/architecture.drawio), kept beside the image so anyone can open it and change it.

**What the templates declare**

![The Bicep visualizer in Visual Studio Code: three groups, one per module. On the left the storage account with its blob service, its images container, its queue service and its orders queue. In the middle the SQL server, its firewall rule, its elastic pool and the databases module. On the right the App Service plan with its applications, their staging slot and the autoscale rule](docs/visualiseur.png)

## How it works

**Adding an application is one line.** The plans and what sits on them are a list at the top of `main.bicep`, and the App Service module is called once per entry. A sixth application joins a plan by being named; nothing else in the deployment has to know about it.

**One parameter decides what exists.** `Dev` runs on F1, `Test` on B1, `Prod` on S1. The staging slot and the autoscale rule are written once and conditioned on the tier that carries them, because asking a free plan for a slot fails the deployment rather than being ignored.

**Names survive a second run.** The four random characters each application carries come from `uniqueString` seeded with the resource group, not from the clock. Deploying twice gives the same five applications instead of five more.

**The pool is Standard, and that is the cheapest tier that holds.** Each database is given a floor of 50 DTU and a ceiling of 200. A Basic pool stops at 5 DTU per database, so it cannot carry those numbers at all. A comment sits where those two numbers are set, so the next reader does not have to work it out.

**Nothing answers in plain text.** The applications and their slots refuse HTTP, ask for TLS 1.2 and turn FTPS off. The storage account refuses HTTP and public blob access. The SQL server asks for TLS 1.2 and lets through a single address range.

**The linter is turned up and the templates pass it.** `bicepconfig.json` turns unused parameters, hand-built resource identifiers, missing parent properties and string concatenation where interpolation belongs into errors; a stale API version stays a warning. The chain stops on either, so `bicep build` reports nothing at all on the five templates.

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

Infrastructure Azure d'une boutique à cinq services, décrite en Bicep et déployée en une commande. Un modèle d'entrée appelle trois modules : les plans App Service et les applications qui les partagent, le serveur SQL avec son pool élastique et ses trois bases, le compte de stockage avec son conteneur privé et sa file.

Les plans et leurs applications tiennent dans une liste : ajouter une sixième application est une ligne, et rien d'autre n'a besoin de le savoir. Un seul paramètre décide du palier tarifaire, F1 en développement, B1 en test, S1 en production, et c'est lui qui fait exister le slot de préproduction et la règle d'auto-scale, qu'un plan gratuit refuse.

Les quatre caractères aléatoires de chaque nom viennent du groupe de ressources et non de l'horloge, donc un second déploiement redonne les mêmes applications. Les applications, leurs slots et le compte de stockage refusent le HTTP ; tous exigent TLS 1.2, le serveur SQL aussi, et le conteneur refuse l'accès public.

Les règles du linter Bicep sont des avertissements par défaut. Ici un paramètre inutilisé ou une propriété parent oubliée sont des erreurs, et la chaîne d'intégration s'arrête sur le moindre diagnostic, avertissement compris.

## Licence

MIT. See [LICENSE](LICENSE).
