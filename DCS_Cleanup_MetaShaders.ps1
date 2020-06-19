$DCSFOLDER = "G:\Games\DCS World\"
$DCSPROFILE = "C:\Users\OzDeaDMeaT\Saved Games\DCS.openbeta\"
$DCS_CLEANUP_LOGFILE = $DCSPROFILE + "DCS_CLEANUP_METASHADERS.log"
$CHECKFILE = $DCSPROFILE + "DCS_CLEANUP_METASHADERS_CHECK.log"

#############################################################################################
### DO NOT EDIT BELOW THIS LINE UNLESS YOU KNOW HOW TO POWERSHELL!
#############################################################################################
Function DCS-Write-Log {
Param ($LogData = "")
if ($LogData -ne "") {
	$Time = get-date -Format "yyyy-MMM-dd--HH`:mm`:ss"
	$TimeStampLog = $Time + " - " + $LogData
	if (-Not (test-path $DCS_CLEANUP_LOGFILE)) {
		new-item $DCS_CLEANUP_LOGFILE -type File -Force
		$newLog = $Time + " - " + "DCS_CLEANUP_LOGFILE CREATED"
		Add-Content $DCS_CLEANUP_LOGFILE $newLog
		}
	Add-Content $DCS_CLEANUP_LOGFILE $TimeStampLog
	write-host $LogData
	} 
}

Function DCS-RECORD-VERSION {
Clear-Content $CHECKFILE
DCS-Write-Log "$CHECKFILE contents cleared"
$DCSEXE_FILE = $DCSFOLDER + "bin\DCS.exe"
$DCSEXE_VERSION = [System.Diagnostics.FileVersionInfo]::GetVersionInfo($DCSEXE_FILE).FileVersion
$VIDEODRV_VERSION = (gwmi win32_VideoController | select DriverVersion).DriverVersion
$Time = get-date -Format "yyyy-MMM-dd--HH`:mm`:ss"
$line0 = "LAST_RUN `:`: $Time"
$line1 = "VID_DRV  `:`: $VIDEODRV_VERSION"
$line2 = "DCS_EXE  `:`: $DCSEXE_VERSION"
Add-Content $CHECKFILE $line0
Add-Content $CHECKFILE $line1
Add-Content $CHECKFILE $line2
DCS-Write-Log "$CHECKFILE contents updated"
}

Function DCS-CHECK-VERSION {
$docleanup = $false
$DCSEXE_FILE = $DCSFOLDER + "bin\DCS.exe"
$DCSEXE_VERSION = [System.Diagnostics.FileVersionInfo]::GetVersionInfo($DCSEXE_FILE).FileVersion
$VIDEODRV_VERSION = (gwmi win32_VideoController | select DriverVersion).DriverVersion
if(test-path $CHECKFILE) {
	$checkdata = get-Content $CHECKFILE
	if (($checkdata | measure).count -ne 0) {
		$PREVIOUS_VIDEODRV_VERSION = $checkdata[1].Split(" `:`: ")[-1]
		$PREVIOUS_DCSEXE_VERSION = $checkdata[2].Split(" `:`: ")[-1]
		if ($VIDEODRV_VERSION -ne $PREVIOUS_VIDEODRV_VERSION) {
			$docleanup = $true
			DCS-Write-Log "Video Driver version mismatch detected, metadata cleanup order issued (Old- $PREVIOUS_VIDEODRV_VERSION -- New- $VIDEODRV_VERSION)"
			}
		if ($DCSEXE_VERSION -ne $PREVIOUS_DCSEXE_VERSION) {
			$docleanup = $true
			DCS-Write-Log "DCS Executable version mismatch detected, metadata cleanup order issued (Old- $PREVIOUS_DCSEXE_VERSION -- New- $DCSEXE_VERSION)"
			}
		}
	else {
		$docleanup = $true
		DCS-Write-Log "No Previous version detected, cleanup order issued"
		}
	}
else {
	new-item -path $CHECKFILE -force
	DCS-Write-Log -LogData "$CHECKFILE not found, new file created"
	$docleanup = $true
	DCS-Write-Log "First Time execution detected, metadata cleanup order issued"
	}
if(-not ($docleanup)) {DCS-Write-Log "No new version detected, cleanup aborted"}
$docleanup
}

Function DCS-DO-FILE-CLEANUP {
Param ($FOLDER,
		$EXT)
if (test-path $FOLDER) {
	DCS-Write-Log "$FOLDER selected for cleanup of $EXT files"
	$FILES = Get-ChildItem -Path $FOLDER | where {$_.Extension -eq $EXT}
	$count = ($FILES | measure).count
	DCS-Write-Log "Found $count $EXT file(s) in $FOLDER"
	if ($count -ne 0) {
		ForEach ($f in $FILES) { 
			$logmsg = "Deleting " + $f.FullName
			
			DCS-Write-Log $logmsg
			#COMMENT OUT THE LINE BELOW TO EXECUTE WITHOUT DELETION
			#sleep 1
			remove-item -Path $f.FullName
			}
		}
	
	}
else {
	DCS-Write-Log "$FOLDER NOT FOUND!!! NOTHING CLEANED UP"
	}
}

Function DCS_METACAHCE_CLEANUP {
<#
.DESCRIPTION
This function is designed to cleanup all the metashader and fxo folders in Eagle Dynamics DCS World.
#>
DCS-Write-Log "DCS_METACAHCE_CLEANUP Started"
#conduct file checks based on information given from the user
if (-not (test-path $DCSPROFILE)) {
	DCS-Write-Log "The DCS Profile folder was not found - $DCSPROFILE - DCS_METACAHCE_CLEANUP TERMINATED!!"
	break
	}

if (-not (test-path $DCSFOLDER)) {
	DCS-Write-Log "The DCS folder was not found - $DCSFOLDER - DCS_METACAHCE_CLEANUP TERMINATED!!"
	break
	}
else {
	$DCSEXE_FILE = $DCSFOLDER + "bin\DCS.exe"
	if (-not (test-path $DCSEXE_FILE)) {
		DCS-Write-Log "The DCS EXE file was not found - $DCSEXE_FILE - DCS_METACAHCE_CLEANUP TERMINATED!!"
		break
		}
	}
if (DCS-CHECK-VERSION) {
	$meta2 = ".meta2"
	$fxo = ".fxo"
	
	$PROFILE_META = $DCSPROFILE + "metashaders2\"
	DCS-DO-FILE-CLEANUP -FOLDER $PROFILE_META -EXT $meta2
	$PROFILE_FXO = $DCSPROFILE + "fxo\"
	DCS-DO-FILE-CLEANUP -FOLDER $PROFILE_FXO -EXT $fxo
	
	#This bit does the detection of the terrains and calls for the deletion of the meta and fxo files
	$TERRAIN_META = "\misc\metacache\dcs"
	$TERRAIN_FXO = "\misc\shadercache"
	$TERRAINS_FOLDER = $DCSFOLDER + "Mods\terrains\"
	$TERRAINS = Get-ChildItem -Path $TERRAINS_FOLDER | where {$_.Attributes -eq "Directory"}
	ForEach ($TERRAIN in $TERRAINS) {
		$logmsg = "Terrain Detected `: " + $TERRAIN.Name
		DCS-Write-Log $logmsg
		$tmpMETA = $TERRAIN.FullName + $TERRAIN_META
		$tmpFXO = $TERRAIN.FullName + $TERRAIN_FXO
		DCS-DO-FILE-CLEANUP -FOLDER $tmpMETA -EXT $meta2
		DCS-DO-FILE-CLEANUP -FOLDER $tmpFXO -EXT $fxo
		}
	DCS-RECORD-VERSION

	}
DCS-Write-Log "DCS_METACAHCE_CLEANUP Finished"
}
RUN_DCS_METACAHCE_CLEANUP
