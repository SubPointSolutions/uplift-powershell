# uplift-powershell
This repository contains reusable PowerShell modules used in the uplift project. 

The uplift project offers consistent Packer/Vagrant workflows and Vagrant boxes specifically designed for SharePoint professionals. It heavy lifts low-level details of the creation of domain controllers, SQL servers, SharePoint farms and Visual Studio installs by providing a codified workflow using Packer/Vagrant tooling.

##  Build status
| Branch  | Status | 
| ------------- | ------------- |  
| master| [![Build status](https://ci.appveyor.com/api/projects/status/4khhqjvhbscpt3qc/branch/master?svg=true)](https://ci.appveyor.com/project/SubPointSupport/uplift-powershell/branch/master) |  
| beta  | [![Build status](https://ci.appveyor.com/api/projects/status/4khhqjvhbscpt3qc/branch/beta?svg=true)](https://ci.appveyor.com/project/SubPointSupport/uplift-powershell/branch/beta)  | 
| dev   | [![Build status](https://ci.appveyor.com/api/projects/status/4khhqjvhbscpt3qc/branch/dev?svg=true)](https://ci.appveyor.com/project/SubPointSupport/uplift-powershell/branch/dev) | 
## How this works
The uplift project is split into several repositories to address particular a piece of functionality:

* [uplift-powershell](https://github.com/SubPointSolutions/uplift-powershell) - reusable PowerShell modules
* [uplift-packer](https://github.com/SubPointSolutions/uplift-packer) - Packer templates for SharePoint professionals
* [uplift-vagrant](https://github.com/SubPointSolutions/uplift-vagrant) - Vagrant plugin to simplify Windows infrastructure provisioning 

The current repository houses reusable PowerShell modules which are used in both Packer builds and Vagrant boxes across the uplift project.

## PowerShell modules
Currently, there are several PowerShell modules which live in the root folder:
* /uplift.core - internal utilities for uplift project automation
* /invoke-uplift - general purpose downloading tool

While `uplift.core` module is used for internal automation and should not be used publically, `invoke-uplift` provides a PowerShell6 module which handles file based routines: downloading files, validating checksum, creating a local repository of all downloaded files, transferring files into Packer/Vagrant VMs.

### Uplift.Core
`uplift.core` is a PowerShell module which simplifies automation tasks within the uplift project. It can but should not be used publically. For the reference, refer to existing PowerShell scripts and all `XXX-UpliftXXX` methods used.

### Invoke-Uplift
`invoke-uplift` is a PowerShell6 module which simplifies file based routines. It is a general purpose tool and can be used freely to automate file downloads, checksum validation, file service and transferring. It is built with PowerShell 6 which makes it portable across platforms; it works well on Windows and MacBook laptops, and even under Windows 2008.

`invoke-uplift` is a PowerShell6 module which simplifies file based routines. It is a general purpose tool and can be used freely to automate file downloads, checksum validation, file service and transferring. For example, `json` configuration can be used to specify which files to download. `invoke-uplift` will build a local repository with downloaded files which then can be used to serve files locally or uploaded to Azure/AWS storages.

This module is an essential part of the uplift project. We rely heavily on its automation to download and build local repository containing all ISOs, installation media, service packs and patches. Refer to following commands to get started:

#### Installing `Invoke-Uplift`
```powershell
# subpointsolutions-staging on myget.org
# https://www.myget.org/feed/subpointsolutions-staging/package/nuget/InvokeUplift

# register 'subpointsolutions-staging' repository
Register-PSRepository -Name "subpointsolutions-staging" -SourceLocation "https://www.myget.org/F/subpointsolutions-staging/api/v2"

# install module under PowerShell 6
pwsh -c 'Install-Module -Name "InvokeUplift" -Repository "subpointsolutions-staging"'
```

#### Using `Invoke-Uplift`
```powershell

# don't forget to switch to pwsh or use pwsh -c 'my-command' all the time
pwsh 

# default run, version and help
invoke-uplift 
invoke-uplift version
invoke-uplift help
```

#### Listing and downloading default resource
`Invoke-Uplift` provides more than a hundred file resources which can be used straight away. These are SharePoint media, ISOs, service packs, updates, parches and others.

```powerhell
invoke-uplift resource list
```

Once you know which resource to download, use resource name with `resource download` command:

```powerhell
# download resource by name
invoke-uplift resource download 7z-1805-x64
invoke-uplift resource download 7z-1805-x64

# download resource by name match, wildcard is used
invoke-uplift resource download 7z-
```

By default, `invoke-uplift` downloads files into `uplift-local-repository` folder within the directory where it was run. This can be changes by using `-r` or `-repository` option:


```powerhell
# download resource into a local folder
invoke-uplift resource download 7z-1805-x64 -r c:/my-files-repository

# download resources into a local folder
invoke-uplift resource download 7z-1805-x64 -repository c:/my-files-repository
```

Default resource provides by `invoke-uplift` can be found in the source code:
* uplift-powershell\invoke-uplift\src\resource-files

```
 - 7z-1805-x64
 - 7z-1805-x86
 - hashicorp-packer-1.3.3-win
 - hashicorp-packer-1.3.3-darwin
 - hashicorp-packer-1.3.2-win
 - hashicorp-packer-1.3.2-darwin
 - hashicorp-vagrant-2.2.3-win
 - hashicorp-vagrant-2.2.3-osx
 - hashicorp-vagrant-2.2.2-win
 - hashicorp-vagrant-2.2.2-osx
 - hashicorp-vagrant-2.1.0-win
 - hashicorp-vagrant-2.1.0-osx
 - jetbrains-resharper-ultimate-2018.3.1
 - jetbrains-resharper-ultimate-2018.1.2
 - ms-dynamics-crm2016-server
 - ms-sharepoint2013-foundation
 - ms-sharepoint2013-rtm
 - ms-sharepoint2016-fp2
 - ms-sharepoint2016-rtm
 - ms-sharepoint2016-lang-pack-ar-sa
 - ms-sharepoint2016-lang-pack-cs-cz
 - ms-sharepoint2016-lang-pack-da-dk
 - ms-sharepoint2016-lang-pack-en-us
 - ms-sharepoint2016-lang-pack-de-de
 - ms-sharepoint2016-lang-pack-fr-fr
 - ms-sharepoint2016-lang-pack-fi-fi
 - ms-sharepoint2016-lang-pack-nl-nl
 - ms-sharepoint2016-lang-pack-he-il
 - ms-sharepoint2016-lang-pack-hi-in
 - ms-sharepoint2016-lang-pack-kk-kz
 - ms-sharepoint2016-lang-pack-it-it
 - ms-sharepoint2016-lang-pack-lv-lv
 - ms-sharepoint2016-lang-pack-pl-pl
 - ms-sharepoint2016-lang-pack-ru-ru
 - ms-sharepoint2016-lang-pack-ro-ro
 - ms-sharepoint2016-lang-pack-es-es
 - ms-sharepoint2016-lang-pack-sv-se
 - ms-sharepoint2016-lang-pack-uk-ua
 - ms-sharepoint2016-update-2016.11.08-KB3127940
 - ms-sharepoint2016-update-2016.11.08-KB3127942
 - ms-sharepoint2016-update-2016.12.13-KB3128014
 - ms-sharepoint2016-update-2016.12.13-KB3128017
 - ms-sharepoint2016-update-2017.01.10-KB3141486
 - ms-sharepoint2016-update-2017.01.10-KB3141487
 - ms-sharepoint2016-update-2017.02.14-KB3141515
 - ms-sharepoint2016-update-2017.02.21-KB3141517
 - ms-sharepoint2016-update-2017.03.14-KB3178672
 - ms-sharepoint2016-update-2017.03.14-KB3178675
 - ms-sharepoint2016-update-2017.04.11-KB3178718
 - ms-sharepoint2016-update-2017.04.11-KB3178721
 - ms-sharepoint2016-update-2017.05.09-KB3191880
 - ms-sharepoint2016-update-2017.05.09-KB3191884
 - ms-sharepoint2016-update-2017.06.13-KB3203432
 - ms-sharepoint2016-update-2017.06.13-KB3203433
 - ms-sharepoint2016-update-2017.07.11-KB3213544
 - ms-sharepoint2016-update-2017.07.11-KB3213543
 - ms-sharepoint2016-update-2017.08.08-KB4011049
 - ms-sharepoint2016-update-2017.08.08-KB4011053
 - ms-sharepoint2016-update-2017.09.12-KB4011127
 - ms-sharepoint2016-update-2017.09.12-KB4011112
 - ms-sharepoint2016-update-2017.10.10-KB4011217
 - ms-sharepoint2016-update-2017.10.10-KB4011161
 - ms-sharepoint2016-update-2017.11.14-KB4011244
 - ms-sharepoint2016-update-2017.11.14-KB4011243
 - ms-sharepoint2016-update-2017.12.12-KB4011576
 - ms-sharepoint2016-update-2017.12.12-KB4011578
 - ms-sharepoint2016-update-2018.01.09-KB4011642
 - ms-sharepoint2016-update-2018.01.09-KB4011645
 - ms-sharepoint2016-update-2018.02.13-KB4011680
 - ms-sharepoint2016-update-2018.03.13-KB4018293
 - ms-sharepoint2016-update-2018.03.13-KB4011687
 - ms-sharepoint2016-update-2018.04.10-KB4018336
 - ms-sharepoint2016-update-2018.04.10-KB4018340
 - ms-sharepoint2016-update-2018.05.08-KB4018381
 - ms-sharepoint2016-update-2018.05.08-KB4018386
 - ms-sharepoint2016-update-2018.06.12-KB4022173
 - ms-sharepoint2016-update-2018.06.12-KB4022178
 - ms-sharepoint2016-update-2018.07.10-KB4022228
 - ms-sharepoint2016-update-2018.08.14-KB4032256
 - ms-sharepoint2016-update-2018.08.14-KB4022231
 - ms-sharepoint2016-update-2018.09.11-KB4092459
 - ms-sharepoint2016-update-2018.10.09-KB4461447
 - ms-sharepoint2016-update-2018.10.09-KB4092463
 - ms-sharepoint2016-update-2018.11.13-KB4461501
 - ms-sharepoint2016-update-2018.12.11-KB4461541
 - ms-sharepoint2016-update-2019.01.08-KB4461598
 - ms-sharepoint-designer-x32
 - ms-sharepoint-designer-x64
 - ms-sql-server2012-sp2
 - ms-sql-server2014-sp2
 - ms-sql-server2016-rtm
 - ms-sql-server-management-studio-17.04
 - ms-visualstudio-2013.5.ent
 - ms-visualstudio-2013.4.ent
 - ms-visualstudio-2015.3.ent
 - ms-visualstudio-2015.2.ent
 - ms-visualstudio-2017.ent-installer
 - ms-visualstudio-2017.ent-dist-office-dev
 - ms-win2012r2-kb-dotnet46-KB3045557
 - ms-win2012r2-kb-2014.03-KB2919442
 - ms-win2012r2-kb-2014.04-KB2919355
 - ms-win-2016-iso-x64-eval
 - ms-win2016-lcu-2018.05.17-KB4103720
 - ms-win2016-lcu-2018.06.21-KB4284833
 - ms-win2016-lcu-2018.06.12-KB4284880
 - ms-win2016-lcu-2018.07.30-KB4346877
 - ms-win2016-lcu-2018.07.24-KB4338822
 - ms-win2016-lcu-2018.07.16-KB4345418
 - ms-win2016-lcu-2018.07.16-KB4338814
 - ms-win2016-lcu-2018.08.30-KB4343884
 - ms-win2016-lcu-2018.08.14-KB4343887
 - ms-win2016-lcu-2018.09.20-KB4457127
 - ms-win2016-lcu-2018.09.11-KB4457131
 - ms-win2016-lcu-2018.10.18-KB4462928
 - ms-win2016-lcu-2018.10.09-KB4462917
 - ms-win2016-lcu-2018.11.27-KB4467684
 - ms-win2016-lcu-2018.11.13-KB4467691
 - ms-win2016-lcu-2018.12.19-KB4483229
 - ms-win2016-lcu-2018.12.11-KB4471321
 - ms-win2016-lcu-2018.12.03-KB4478877
 - ms-win2016-lcu-2019.01.17-KB4480977
 - ms-win2016-lcu-2019.01.08-KB4480961
 - ms-win2016-ssu-2018.05.17-KB4132216
 - oracle-virtual-box-5.2.18-win
 - oracle-virtual-box-5.2.18-osx
 ```


#### Authoring custom file resources
By default, `invoke-uplift` looks for `*.resource.json` files within its PowerShell module folder and two levels within the current directory on where it was run. These  `*.resource.json` files are where file resources are defined.

Such behaviour makes it easy to author project-specific file resources. `invoke-uplift` sees all resources defined within the current folder and two levels deep. 

For example, create `my-files.resource.json` file as follows:

```js
{
  "resources": [
    {
      "id": "my-7z-1805-x64",
      "uri": "https://www.7-zip.org/a/7z1805-x64.exe",

      "checksum": "C1E42D8B76A86EA1890AD080E69A04C75A5F2C0484BDCD838DC8FA908DD4A84C",
      "checksum_type": "SHA256",
      "metadata": {
        "help_link": "https://www.7-zip.org/download.html"
      }
    },
    {
      "id": "my-7z-1805-x86",
      "uri": "https://www.7-zip.org/a/7z1805.exe",

      "checksum": "647A9A621162CD7A5008934A08E23FF7C1135D6F1261689FD954AA17D50F9729",
      "checksum_type": "SHA256",
      "metadata": {
        "help_link": "https://www.7-zip.org/download.html"
      }
    }
  ]
}
```

Once done, list and download resources as usual:

```powerhell
# list resources
invoke-uplift resource list my- 

# download resources
invoke-uplift resource download my- -r c:/my-files-repository
invoke-uplift resource download 7z-1805-x64 -repository c:/my-files-repository
```

#### Forced file download
By default, files are downloaded with checksum verification. Assuming that the first download was successful, consequent downloading won't download anything. That makes downloading experience fast.

Sometimes we need to re-download files overriding existing ones. It can be done with `-f` or `-force` flag:

```powerhell
# list resources
invoke-uplift resource list my- 

# force download resources
invoke-uplift resource download my- -r c:/my-files-repository -f
invoke-uplift resource download 7z-1805-x64 -repository c:/my-files-repository -force
```

#### Debug trace level
By default, `invoke-uplift` reports only important information. Debug trace can be enabled with `-d` or `-debug` flag:

```powerhell
# list resources
invoke-uplift resource list my -d

# force download resources
invoke-uplift resource download my- -r c:/my-files-repository -f -d
invoke-uplift resource download 7z-1805-x64 -repository c:/my-files-repository -force -d
```

## Local development workflow
Local development automation uses [Invoke-Build](https://github.com/nightroman/Invoke-Build) based tasks

To get started, get the latest `dev` branch or fork the repo on the GitHub:
```shell
# get the source code
git clone https://github.com/SubPointSolutions/subpointsolutions-docs.git
cd subpointsolutions-docs

# checkout the dev branch
git checkout dev

# make sure we are on dev branch
git status

# optionally, pull the latest
git pull
```

Local development experience consists of [Invoke-Build](https://github.com/nightroman/Invoke-Build) tasks. Two main files are `.build.ps1` and `.build-helpers.ps1`. Use the following tasks to get started and refer to `Invoke-Build` documentation for additional help.

Change the current directory to the corresponding PowerShell module and run the following commands:

```powershell
# show available tasks
invoke-build ?

# invoke default build
invoke-build 
invoke-build DefaultBuild

# invoke QA automation
invoke-build QA

# deploy/publish module
invoke-build ReleaseModule
```

## Feature requests, support and contributions
All contributions are welcome. If you have an idea, create [a new GitHub issue](https://github.com/SubPointSolutions/uplift-powershell/issues). Feel free to edit existing content and make a PR for this as well.