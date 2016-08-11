#Datacenter/ClusterIfAny/Name/Socket/CorePhysical/CoreLogical/PhysicalCorePerCPU/2012R2DatacenterLicense/OldCost/2Cores/Price/ExtraPrice/Difference


function Get-CostUpgradeToWin2016{
<#
.SYNOPSIS
Analyse your VMware environment to estimate the cost of upgrading from Windows 2012R2 Datacenter to 2016.
Need to be connected to one vCenter
#>
	[CmdletBinding()]
	param(
	[long]$Price2012R2DatacenterTwoProcessor = 6155,
	[long]$Price2016DatacenterTwoCorePack = ($Price2012R2DatacenterTwoProcessor/8),
	[Parameter(Mandatory=$true,HelpMessage="Enter the path for the report. EX: C:\Temp\ReportCostUpgradeToWin2016.html")]
	[string]$Path,	
	)
	process{
	#Analyse all hosts with the assumption that they are licensed with Windows Datacenter 2012R2
		$AnalyseForAllHosts = get-datacenter | foreach{
			$Datacenter = $_
				get-vmhost -location $_ | foreach{
				$MyHost = $_
				$NumCpuPackages = $_.extensiondata.hardware.cpuinfo.NumCpuPackages
				$NumCpuCores = $_.extensiondata.hardware.cpuinfo.NumCpuCores
				$PhysicalCoresPerProcessor = $NumCpuCores/$NumCpuPackages
				$TotalLogicalCores = $_.extensiondata.hardware.cpuinfo.numCpuThreads
				
				if($NumCpuPackages -eq 1){
				$2012R2DatacenterLicenseNeeded = 1
				}
				Else{
				$2012R2DatacenterLicenseNeeded = (($NumCpuPackages / 2) + ($NumCpuPackages % 2))	
				}

				if($PhysicalCoresPerProcessor -lt 8){
				#Each physical processor will be required to be licensed with a minimum of 8 physical cores
				$PhysicalCoresPerProcessorToBeLicensed = 8
				}
				Else{
				$PhysicalCoresPerProcessorToBeLicensed = $PhysicalCoresPerProcessor
				}
				#Each physical server will be required to be licensed for all physical cores
				$TotalPhysicalCoresToBeLicensed = $PhysicalCoresPerProcessorToBeLicensed * $NumCpuPackages
				
				if($TotalPhysicalCoresToBeLicensed -lt 16){
				#Each physical server will be required to be licensed with a minimum of two processors, totaling a minimum of 16 physical cores
				$TotalPhysicalCoresToBeLicensed = 16
				}
				
				#Core licenses will be sold in two-core packs
				$2016DatacenterTwoCorePackNeeded = $TotalPhysicalCoresToBeLicensed/2
				
				$OldPrice2012R2 = $Price2012R2DatacenterTwoProcessor * $2012R2DatacenterLicenseNeeded
				$NewPrice2016 = $Price2016DatacenterTwoCorePack * $2016DatacenterTwoCorePackNeeded
				$Difference = $NewPrice2016 - $OldPrice2012R2
				
					   $Output = New-Object -Type PSObject -Prop ([ordered]@{
						'Datacenter' = $Datacenter.name
						'Cluster' = (Get-Cluster -VMHost $MyHost).Name
						'Host' = $MyHost.Name
						'Processor' = $NumCpuPackages
						'PhysicalCoresPerProcessor' = $PhysicalCoresPerProcessor
						'TotalPhysicalCore' = $NumCpuCores
						'TotalLogicalCore' = $TotalLogicalCores
						'2012R2DatacenterLicenseNeeded' = $2012R2DatacenterLicenseNeeded
						'OldPrice2012R2' = $OldPrice2012R2
						'2016DatacenterTwoCorePackNeeded' = $2016DatacenterTwoCorePackNeeded
						'NewPrice2016' = $NewPrice2016
						'PriceIncrease' = $Difference 
						'%Increase' =  [math]::Round(($Difference / $OldPrice2012R2)*100)
						})
						Write-Output $Output
				}
			}
	}
	
	#ReportForCluster
	$AnalyseForAllHosts |  select -unique Datacenter | foreach{
	$DatacenterName = $_
	
		$AnalyseForAllHosts | where {$_.Datacenter -eq $DatacenterName} | select -unique Cluster | where {$_.Cluster} | foreach{
		$ClusterName = $_
		#Not check to identify if guest or server OS for windows VMs
		$TotalWindowsVM = (get-vm -location (get-cluster -name $ClusterName -Location (get-datacenter -name $DatacenterName) ) | where {$_.extensiondata.config.guestId -Match "win"} | measure-object).count
			if($TotalWindowsVM){
			$AllHostsInThisCluster = $AnalyseForAllHosts | where {$_.Dacenter -eq $DatacenterName -AND $_.Cluster -eq $ClusterName}
			$ClusterHost = ($AllHostsInThisCluster | measure-object).count
			$ClusterProcessor = 0
			$ClusterPhysicalCore = 0
			$CLuster2012R2DatacenterLicenseNeeded = 0			
			$ClusterTotal2016DatacenterTwoCorePackNeeded = 0
			$AllHostsInThisCluster | foreach{
			$ClusterProcessor = $ClusterProcessor + $_.Processor
			$ClusterPhysicalCore = $ClusterProcessor + $_.TotalPhysicalCore
			$CLuster2012R2DatacenterLicenseNeeded = $CLuster2012R2DatacenterLicenseNeeded + $_.2012R2DatacenterLicenseNeeded
			$ClusterTotal2016DatacenterTwoCorePackNeeded = $ClusterTotal2016DatacenterTwoCorePackNeeded + $_.2016DatacenterTwoCorePackNeeded
			}		
			$ClusterOldPrice2012R2 = $CLuster2012R2DatacenterLicenseNeeded * $Price2012R2DatacenterTwoProcessor
			$ClusterNewPrice2012R2 = $ClusterTotal2016DatacenterTwoCorePackNeeded * $Price2016DatacenterTwoCorePack
			$ClusterPriceIncrease = $ClusterNewPrice2012R2 - $ClusterOldPrice2012R2
			$Cluster%Increase = [math]::Round(($ClusterPriceIncrease / $ClusterOldPrice2012R2)*100)
			
			}			
		}	
	}
	
	#ReportForStandaloneHost
	
	
}







#http://pubs.vmware.com/vsphere-60/topic/com.vmware.wssdk.apiref.doc/vim.vm.GuestOsDescriptor.GuestOsIdentifier.html?path=7_1_0_2_3_15_10#netware6Guest

#http://hostilecoding.blogspot.no/2014/03/vmware-fancy-html-reports-using-powercli.html


$Test = import-csv -path "C:\temp\Test.csv"
$AnalyseForAllHosts  = $Test

	$AnalyseForAllHosts |  select -unique Datacenter | foreach{
	$DatacenterName = $_
	
		$AnalyseForAllHosts | where {$_.Datacenter -eq $DatacenterName} | select -unique Cluster | where {$_.Cluster} | foreach{
		$ClusterName = $_
		#Not check to identify if guest or server OS for windows VMs
		$TotalWindowsVM = (get-vm -location (get-cluster -name $ClusterName -Location (get-datacenter -name $DatacenterName) ) | where {$_.extensiondata.config.guestId -Match "win"} | measure-object).count
			if($TotalWindowsVM){
			$AllHostsInThisCluster = $AnalyseForAllHosts | where {$_.Dacenter -eq $DatacenterName -AND $_.Cluster -eq $ClusterName}
			$ClusterHost = ($AllHostsInThisCluster | measure-object).count
			$ClusterProcessor = 0
			$ClusterPhysicalCore = 0
			$CLuster2012R2DatacenterLicenseNeeded = 0			
			$ClusterTotal2016DatacenterTwoCorePackNeeded = 0
			$AllHostsInThisCluster | foreach{
			$ClusterProcessor = $ClusterProcessor + $_.Processor
			$ClusterPhysicalCore = $ClusterProcessor + $_.TotalPhysicalCore
			$CLuster2012R2DatacenterLicenseNeeded = $CLuster2012R2DatacenterLicenseNeeded + $_.LicenseNeeded2012R2
			$ClusterTotal2016DatacenterTwoCorePackNeeded = $ClusterTotal2016DatacenterTwoCorePackNeeded + $_.TwoCorePackNeeded2016
			}		
			$ClusterOldPrice2012R2 = $CLuster2012R2DatacenterLicenseNeeded * $Price2012R2DatacenterTwoProcessor
			$ClusterNewPrice2012R2 = $ClusterTotal2016DatacenterTwoCorePackNeeded * $Price2016DatacenterTwoCorePack
			$ClusterPriceIncrease = $ClusterNewPrice2012R2 - $ClusterOldPrice2012R2
			$ClusterIncrease = [math]::Round(($ClusterPriceIncrease / $ClusterOldPrice2012R2)*100)
			Write-host "cluster $ClusterName with $ClusterHost $ClusterProcessor $ClusterPhysicalCore $CLuster2012R2DatacenterLicenseNeeded $ClusterTotal2016DatacenterTwoCorePackNeeded $ClusterOldPrice2012R2 $ClusterNewPrice2012R2 $ClusterPriceIncrease  $ClusterIncrease"
			
			}			
		}	
	}







$2012R2DatacenterLicensePrice = 5000
$2016_2CorePackPrice = $2012R2DatacenterLicensePrice / 8


get-datacenter | foreach{
$Datacenter = $_
	get-vmhost -location $_ | foreach{
	$MyHost = $_
	$NumCpuPackages = $_.extensiondata.hardware.cpuinfo.NumCpuPackages
	$NumCpuCores = $_.extensiondata.hardware.cpuinfo.NumCpuCores
	$PhysicalCoresPerProcessor = $NumCpuCores/$NumCpuPackages
	$TotalLogicalCores = $_.extensiondata.hardware.cpuinfo.numCpuThreads
	
	if($NumCpuPackages -eq 1){
	$2012R2DatacenterLicense = 1
	}
	Else{
	$2012R2DatacenterLicense = (($NumCpuPackages / 2) + ($NumCpuPackages % 2))	
	}

	if($PhysicalCoresPerProcessor -lt 8){
	$PhysicalCoresPerProcessorToBeLicensed = 8
	}
	Else{
	$PhysicalCoresPerProcessorToBeLicensed = $PhysicalCoresPerProcessor
	}
	$TotalPhysicalCoresToBeLicensed = $PhysicalCoresPerProcessorToBeLicensed * $NumCpuPackages
	
	if($TotalPhysicalCoresToBeLicensed -lt 16){
	$TotalPhysicalCoresToBeLicensed = 16
	}
	
	$Total2016_2CorePackNeeded = $TotalPhysicalCoresToBeLicensed/2
	
	$2012R2OLDPrice = $2012R2DatacenterLicensePrice * $2012R2DatacenterLicense
	$2016NewPrice = $2016_2CorePackPrice * $Total2016_2CorePackNeeded
	$Difference = $2016NewPrice - $2012R2OLDPrice
	
		   $Output = New-Object -Type PSObject -Prop ([ordered]@{
			'Datacenter' = $Datacenter.name
			'Cluster' = (Get-Cluster -VMHost $MyHost).Name
			'Host' = $MyHost.Name
			'Processors' = $NumCpuPackages
			'PhysicalCoresPerProcessor' = $PhysicalCoresPerProcessor
			'TotalPhysicalCores' = $NumCpuCores
			'TotalLogicalCores' = $TotalLogicalCores
			'2012R2DatacenterLicenseNeeded' = $2012R2DatacenterLicense
			'2012R2DatacenterLicensePrice' = $2012R2DatacenterLicensePrice
			'2012R2OLDPrice' = $2012R2OLDPrice
			'2016_2CorePackNeeded' = $Total2016_2CorePackNeeded
			'2016NewPrice' = $2016NewPrice
			'Difference' = $Difference 
			'Percentage' = ($Difference /  $2012R2OLDPrice)*100
			})
			Write-Output $Output
	}
} | ogv

Datacenter/Cluster/TotalHost/WindowsServerVM/TotalVMs/DatacenterLicenseNeeded/PreviousCost/PackCoreNeede/NewCost/Difference/%Increase

Datacenter/Standalone host/WindowsServerVM/TotalVMs/DatacenterLicenseNeeded/PreviousCost/PackCoreNeede/NewCost/Difference/%Increase

Cluster Summary
Host
Standalone Host
Host

IncreaseCost
