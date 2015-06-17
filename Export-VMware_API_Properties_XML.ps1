function Export-VMware_API_Properties_XML{
<#
.SYNOPSIS
Export all properties of a VMware View object as an XML file.

.NOTES
Author: Christophe Calvet
Blog: http://thecrazyconsultant.com/export-api-properties-xml-powercli/

.PARAMETER ToAnalyse
The VMware View Object to analyse.

.PARAMETER PropertyToExclude
All properties defined in this array will not be exported in the xml file.
The property to be excluded has to be provided with the full path from the object analysed, always starting with "."
For example to remove BiosInformation for a HostSytem object use '.hardware.biosinfo' in the array.

.PARAMETER Path
Full path of the exported xml files.

.PARAMETER PropertyPath
Do not use this parameter. It is for internal use only.

.PARAMETER ScriptFirstIteration
Do not use this parameter. It is for internal use only.

.EXAMPLE
$ObjectToAnalyse = (get-vmhost "NameOfAVMHost").extensiondata
$PropertyToExclude = @('.client','.hardware.biosinfo')
Export-VMware_API_Properties_XML -ToAnalyse $ObjectToAnalyse -PropertyToExclude $PropertyToExclude -Path 'C:\Temp\NameOfAVMHost_API_Properties.xml'
#>
param(
$ToAnalyse,
$PropertyToExclude,
$Path,
$PropertyPath,
[boolean]$ScriptFirstIteration = $True
)
	process{
	
	#Initialize the script only for the first iteration.
	If($ScriptFirstIteration){
	    #Capture in an array all enumeration type in VMware.
		$ArrayVMwareEnum = @()
		(([appdomain]::currentdomain.GetAssemblies()).Modules | Where-Object {$_.Name -eq 'vmware.vim.dll'}).Assembly.modules.gettypes() | where {$_.isenum -eq $true} | foreach-object{
		$ArrayVMwareEnum = $ArrayVMwareEnum + $_.fullname
		}
		
		#Initialize the StreamWriter
		If($stream){
		$stream.close()
		}
		$stream = [System.IO.StreamWriter] $Path
		$NewOutputWithTab ='<?xml version="1.0" encoding="UTF-8"?>'
		$stream.WriteLine($NewOutputWithTab)
		
	}
			#Get the type of the object analysed and filter it to match entries in the ArrayVMwareEnum
			$MytypeUnfiltered = $ToAnalyse.pstypenames[0]
			$Mytype = $MytypeUnfiltered.replace("System.Nullable``1[[","").replace("System.EventHandler``1[[","")
			$Mytype = $Mytype -replace ',.*', '' 
			$NewOutputWithTab = "<" + $Mytype + ">"
			$stream.WriteLine($NewOutputWithTab)
			
				#It the object is of type enum, just write all the content in the XML file.
				if($ArrayVMwareEnum -contains $Mytype){				
					$ToAnalyse | foreach{
					#CDATA is used to avoid issue with all XML special characters
					$Towrite = '<![CDATA['
					$stream.WriteLine($Towrite)
					$Towrite = ("$_")
					$stream.WriteLine($Towrite)
					$Towrite = (']]>')
					$stream.WriteLine($Towrite)
					}
				}
				
				#If the object is not of a type matching an enum
				Else{
					#GetAllProperty of the object and for each
					$ToAnalyse | gm | where {$_.MemberType -eq "Property"}| sort name | foreach{
					$PropertyName = $_.Name
					#PropertyPath2 is used to identify the full path of the property...
					$PropertyPath2 = $PropertyPath + "." + $PropertyName
					#...and check if this property should be excluded
						if($PropertyToExclude -notcontains $PropertyPath2 ){
						#Now we store the content of this specific property in a variable.
						$Value = $ToAnalyse.$PropertyName
								#If the value is empty nothing will be stored in the xml files.
								if ($Value -ne $Null){
								
								$NewOutputWithTab = "<" + $PropertyName + ">"
								$stream.WriteLine($NewOutputWithTab)
							
									$Value | foreach{
										$Subtype = $_.pstypenames[0]
										#If the property is of type VMware, he function is run recursively.
										if ($Subtype -match "VMware.VIM*"){
										Export-VMware_API_Properties_XML -ToAnalyse $_ -PropertyToExclude $PropertyToExclude -ScriptFirstIteration $False -PropertyPath $PropertyPath2
										}
										#This is a standard property, for example a boolean or string, in that case we just write the content in the xml file.
										Else{
										$Towrite = '<![CDATA['
										$stream.WriteLine($Towrite)
										$Towrite = ("$_")
										$stream.WriteLine($Towrite)
										$Towrite = (']]>')
										$stream.WriteLine($Towrite)
										}
									}
								$NewOutputWithTab = "</" + $PropertyName + ">"
								$stream.WriteLine($NewOutputWithTab)
								}
		
						}
					}
				}	
			$NewOutputWithTab = "</" + $Mytype + ">"
			$stream.WriteLine($NewOutputWithTab)
			
			If($ScriptFirstIteration){
			$stream.close()
			}
			
	}
}
