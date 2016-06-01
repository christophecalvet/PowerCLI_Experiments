
Function Export-APIPropertiesRecursiveToXMLWithoutDuplicates{
param(
$ObjectToAnalyse,
$IgnoreNestedObjectForInitialObject
)
	process{
		$objectToAnalyseFullName = $ObjectToAnalyse.fullname
		If($Global:AllObjectsAnalysed -contains $objectToAnalyseFullName){ 		#Avoid infinite loop
		$xmlWriter.WriteElementString($objectToAnalyseFullName,"ALREADY ANALYSED")
		}
		Else{
		$Global:AllObjectsAnalysed = $Global:AllObjectsAnalysed + $objectToAnalyseFullName 	#Avoid infinite loop
		
		$xmlWriter.WriteStartElement($objectToAnalyseFullName)
		
			#Extract the basetype of the object analysed
			$BaseType = $ObjectToAnalyse.BaseType
			$xmlWriter.WriteElementString("BaseType",$BaseType)
			
			#Extract all properties of the object
			$xmlWriter.WriteStartElement("Properties")			
							$ObjectToAnalyse.getproperties() | foreach{
								if ($_.Name -eq "LinkedView"){
								#LinkedView is only a "PowerCLI" concept
								}
								Else{
								#Line below to be used in a separate script
								$global:AllPropertiesAndPropertiesOfChildObject = $AllPropertiesAndPropertiesOfChildObject + $_.name
									$xmlWriter.WriteStartElement($_.Name)
										$xmlWriter.WriteElementString("PropertyType",$_.PropertyType)
										$PropertyType = "$($_.PropertyType)"
										$PropertytypeFiltered = $PropertyType.replace("System.Nullable``1[[","").replace("]]","").replace("[]","")
											if( $PropertytypeFiltered -match "VMware.V*"){								
												if ($ArrayVMwareEnum -contains $PropertytypeFiltered ){
												#Line below to be used in a separate script
												$global:AllPropertiesAndPropertiesOfChildObject = $AllPropertiesAndPropertiesOfChildObject + "value__"
													$xmlWriter.WriteStartElement($PropertytypeFiltered)
														$xmlWriter.WriteStartElement("Enumerationdetails")
															($Global:AllVMwareVimObject | where {$_.fullname -eq $PropertytypeFiltered}).declaredmembers | sort name | foreach-object{
															$xmlWriter.WriteStartElement($_.name)
															$xmlWriter.WriteEndElement()
															}
														$xmlWriter.WriteEndElement() #Matching "Enumerationdetails"
													$xmlWriter.WriteEndElement() #Matching $PropertytypeFiltered (which is an enum object)"
												}										
												Else{
													$Global:AllVMwareVimObject | where {$_.fullname -eq $PropertytypeFiltered} | foreach{
													Export-APIPropertiesRecursiveToXMLWithoutDuplicates -ObjectToAnalyse $_
													}
												}											
											}
									$xmlWriter.WriteEndElement() #Matching $_.Name which is the property name
								}	
							}
				$xmlWriter.WriteEndElement() #Matching the start element "Properties"
				
				#Extract all objects that extend the analysed object if any.
				if($IgnoreNestedObjectForInitialObject){
				#Only for the first object it is possible to prevent the export of all associated Nested Objects. The nested objects associated to child objects will be exported
				}
					Else{
					If ($Global:AllVMwareVimObject | where {$_.baseType.fullname -eq $objectToAnalyseFullName}){
						$xmlWriter.WriteStartElement("ExtendedBy")
							$Global:AllVMwareVimObject | where {$_.baseType.fullname -eq $objectToAnalyseFullName} | foreach{
							Export-APIPropertiesRecursiveToXMLWithoutDuplicates -ObjectToAnalyse $_ 
							}
						$xmlWriter.WriteEndElement() #Matching the start element "ExtendedBy"
					}
				}
				
		$xmlWriter.WriteEndElement() #Matching the start element $objectToAnalyseFullName
		}	
	}

}


Function Export-APIPropertiesRecursiveToXMLWithDuplicates{
param(
$ObjectToAnalyse,
$AllObjectsAnalysedInThisBranch,
$IgnoreNestedObjectForInitialObject
)
	process{
		$objectToAnalyseFullName = $ObjectToAnalyse.fullname
		If($AllObjectsAnalysedInThisBranch -contains $objectToAnalyseFullName){ 		#Avoid infinite loop
		$xmlWriter.WriteElementString($objectToAnalyseFullName,"Already analysed in a parent object")
		}
		Else{
		$AllObjectsAnalysedInThisBranch2 = $AllObjectsAnalysedInThisBranch + $objectToAnalyseFullName 	#Avoid infinite loop
		
		$xmlWriter.WriteStartElement($objectToAnalyseFullName)
		
			#Extract the basetype of the object analysed
			$BaseType = $ObjectToAnalyse.BaseType
			$xmlWriter.WriteElementString("BaseType",$BaseType)
			
			#Extract all properties of the object
			$xmlWriter.WriteStartElement("Properties")			
							$ObjectToAnalyse.getproperties() | foreach{
								if ($_.Name -eq "LinkedView"){
								#LinkedView is only a "PowerCLI" concept
								}
								Else{
								#Line below to be used in a separate script
								$global:AllPropertiesAndPropertiesOfChildObject = $AllPropertiesAndPropertiesOfChildObject + $_.name
									$xmlWriter.WriteStartElement($_.Name)
										$xmlWriter.WriteElementString("PropertyType",$_.PropertyType)
										$PropertyType = "$($_.PropertyType)"
										$PropertytypeFiltered = $PropertyType.replace("System.Nullable``1[[","").replace("]]","").replace("[]","")
											if( $PropertytypeFiltered -match "VMware.V*"){								
												if ($ArrayVMwareEnum -contains $PropertytypeFiltered ){
												#Line below to be used in a separate script
												$global:AllPropertiesAndPropertiesOfChildObject = $AllPropertiesAndPropertiesOfChildObject + "value__"
													$xmlWriter.WriteStartElement($PropertytypeFiltered)
														$xmlWriter.WriteStartElement("Enumerationdetails")
															($Global:AllVMwareVimObject | where {$_.fullname -eq $PropertytypeFiltered}).declaredmembers | sort name | foreach-object{
															$xmlWriter.WriteStartElement($_.name)
															$xmlWriter.WriteEndElement()
															}
														$xmlWriter.WriteEndElement() #Matching "Enumerationdetails"
													$xmlWriter.WriteEndElement() #Matching $PropertytypeFiltered (which is an enum object)"
												}										
												Else{
													$Global:AllVMwareVimObject | where {$_.fullname -eq $PropertytypeFiltered} | foreach{
													Export-APIPropertiesRecursiveToXMLWithDuplicates -ObjectToAnalyse $_ -AllObjectsAnalysedInThisBranch $AllObjectsAnalysedInThisBranch2  
													}
												}											
											}
									$xmlWriter.WriteEndElement() #Matching $_.Name which is the property name
								}	
							}
				$xmlWriter.WriteEndElement() #Matching the start element "Properties"
				

			
				#Extract all objects that extend the analysed object if any.
				if($IgnoreNestedObjectForInitialObject){
				#Only for the first object it is possible to prevent the export of all associated Nested Objects. The nested objects associated to child objects will be exported
				}
				Else{
					If ($Global:AllVMwareVimObject | where {$_.baseType.fullname -eq $objectToAnalyseFullName}){
						$xmlWriter.WriteStartElement("ExtendedBy")
							$Global:AllVMwareVimObject | where {$_.baseType.fullname -eq $objectToAnalyseFullName} | foreach{
							Export-APIPropertiesRecursiveToXMLWithDuplicates -ObjectToAnalyse $_ -AllObjectsAnalysedInThisBranch $AllObjectsAnalysedInThisBranch2  
							}
						$xmlWriter.WriteEndElement() #Matching the start element "ExtendedBy"
					}
				}
				
		$xmlWriter.WriteEndElement() #Matching the start element $objectToAnalyseFullName
		}	
	}

}





#This array contains all Enumerated Types
$Global:ArrayVMwareEnum = @()
(([appdomain]::currentdomain.GetAssemblies()).Modules | Where-Object {$_.Name -eq 'vmware.vim.dll'}).Assembly.modules.gettypes() | where {$_.isenum -eq $true} | foreach-object{
$ArrayVMwareEnum = $ArrayVMwareEnum + $_.fullname
}	

#Only in use for Export-APIPropertiesRecursiveToXMLWithoutDuplicates. If one object has already been analysed anywhere it will not be analysed again
$Global:AllObjectsAnalysed =@()

#Only in use for Export-APIPropertiesRecursiveToXMLWithDuplicates. If one object has already been analysed in the same "branch" it will not be analysed again
#It prevents infinite loop, moreover it will offer a complete picture...but slower to generate.	
$AllObjectsAnalysedInThisBranch = @()

#The array below will contains the name of all properties of the object analysed and properties of all child objects. (The result will be used in another script)
$global:AllPropertiesAndPropertiesOfChildObject = @()

#All VMwareVimObject will be stored once in this global variable		
$Global:AllVMwareVimObject = (([appdomain]::currentdomain.GetAssemblies()).Modules | Where-Object {$_.Name -eq 'vmware.vim.dll'}).Assembly.modules.gettypes()
 
#Modify the full name according to the object that you would like to analyse
$FullnameOfTheObjectToAnalyse =  "VMware.Vim.ClusterComputeResource" 
$InitialObjectToAnalyse = $Global:AllVMwareVimObject | where {$_.FullName -eq $FullnameOfTheObjectToAnalyse }



$PathOfTheXMLFile = "c:\temp\API_" + $FullnameOfTheObjectToAnalyse.replace("VMware.Vim.","").replace("VMware.VIM.","") + ".xml"
$XmlWriter = New-Object System.XMl.XmlTextWriter($PathOfTheXMLFile,$Null)
$xmlWriter.Formatting = 'Indented'
$xmlWriter.Indentation = 1
$XmlWriter.IndentChar = "`t"
	$xmlWriter.WriteStartDocument()
	$xmlWriter.WriteProcessingInstruction("xml-stylesheet", "type='text/xsl' href='style.xsl'")
				#By default use the "Export-APIPropertiesRecursiveToXMLWithoutDuplicates" that executes faster.
				#It is possible to set "IgnoreNestedObject" to False if you want 
				Export-APIPropertiesRecursiveToXMLWithoutDuplicates -ObjectToAnalyse $InitialObjectToAnalyse -IgnoreNestedObjectForInitialObject $True
				
				#Or comment the above line, and uncoment the below line to use Export-APIPropertiesRecursiveToXMLWithDuplicates
				#Export-APIPropertiesRecursiveToXMLWithDuplicates -ObjectToAnalyse $InitialObjectToAnalyse -AllObjectsAnalysedInThisBranch $AllObjectsAnalysedInThisBranch -IgnoreNestedObjectForInitialObject $False

	$xmlWriter.WriteEndDocument()
$xmlWriter.Flush()
$xmlWriter.Close()

#The main goal of the script was to extract all properties of all child objects.
#And copy paste the properties exported in another script
$global:AllPropertiesAndPropertiesOfChildObject | sort-object -unique | foreach-object{
$NewValue = '''' + $_ + ''',`'
$NewValue
}