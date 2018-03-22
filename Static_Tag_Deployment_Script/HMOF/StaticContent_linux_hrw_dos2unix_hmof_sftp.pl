# Name	:	static_content.pl
# Author:	Moolchand/Dineshwar
# Version:	7.0
# Use	:	Export static content from SVN and upload on CHIP using given PushList.
# Softwares Used : SVN command line client, GNU tar, ncftp, perl
#Revision number of Tag : Updated by Deepak Pant
# Declaring the modules
use lib "/home/deepak/perl5/lib/perl5";
use File::Path qw(remove_tree make_path rmtree);
use File::Copy;
use File::Basename;
use MIME::Lite;
use Net::SMTP;
use Cwd;
use Socket;
use Sys::Hostname;
use Archive::Zip;


$ScriptHome = getcwd;
#$TarballArchive = '/var/rm_share/TarballArchive';
#$LogsArchive = '/var/rm_share/LogsArchive';
$TarballArchive = '/opt/exports/TarballArchive';
$LogsArchive = '/opt/exports/LogsArchive';

$Pushlist_count =0;

make_path($TarballArchive);
make_path($LogsArchive);

my $host = hostname();
#my $username = uc(getlogin());
my $username = uc($ENV{USER});
chomp $username;

#my $addr = inet_ntoa(scalar(gethostbyname($name)) || 'localhost');
my $addr = `/sbin/ifconfig eth0 | grep "inet addr" | cut -d ":" -f2 | cut -d " " -f1`;
chomp $addr;

# ##################################
# Specify here FTP login information
# ##################################
#$ftphost = "208.85.124.41";
#$ftpuser   = "gallenor";
#$ftppassword = 'trait\&ft';

######################################################################
## Send Mail Function
sub SendMail
{
MIME::Lite->send('smtp', 'smtp.hmco.com'); ### Updated SMTP ServerIP Address to Send Mail
$sub = $_[0];  ### Getting Subject as argument
$mailfile = $_[1]; ### Getting attachment file path as argument

### Message Details
$msg = MIME::Lite->new(
From =>'ReleaseEng@hmhpub.com',
#To =>'release.engineering@niit.com,release.engineering@hmhco.com',
To =>'deepak.pant@niit.com',
#To =>'moolchand@niit.com,dineshwar.kumar@niit.com',
#To =>'dineshwar.kumar@niit.com',
Subject =>"$sub",
Type => 'multipart/mixed'
);

$msg->attach(
	Type =>'TEXT',
	Data =>"
		Hi, \n
			Please find the attached status output of the Static Content perl script. \n

		Regards, \n
		Release Eng. Team \n
	
		*** This is System Generated Mail. Kindly Do Not Reply To This e-Mail. *** \n
		"	
);

### Attachement Details
$msg->attach(
	Type =>'zip',
	Path =>"$mailfile",
	Disposition => 'attachment'
);

$msg->send();
}
######################################################################
sub CreateZip
{
$nuArgs = $#_ + 1;

$ZipFileName = $_[0];

$file1 = $_[1];
$file2 = $_[2];
$file3 = $_[3];
$file4 = $_[4];

$object = Archive::Zip->new();

if ($nuArgs == 2)
	{
	@files1 = <./$file1>;
	if (-e $ZipFileName) {$object->read($ZipFileName); foreach $file (@files1) {$object->addFile($file);} $object->overwrite();}
	else {foreach $file (@files1) {$object->addFile($file);} $object->writeToFileNamed($ZipFileName);}
	}

if ($nuArgs == 3)
	{
	@files1 = <./$file1>;
	@files2 = <./$file2>;
	if (-e $ZipFileName)
		{
		$object->read($ZipFileName); 
		foreach $file (@files1) {$object->addFile($file);}
		foreach $file (@files2) {$object->addFile($file);} 
		$object->overwrite();
		}
	else
		{
		foreach $file (@files1) {$object->addFile($file);} 
		foreach $file (@files2) {$object->addFile($file);}
		$object->writeToFileNamed($ZipFileName);
		}
	}

if ($nuArgs == 4)
	{
	@files1 = <./$file1>;
	@files2 = <./$file2>;
	@files3 = <./$file3>;
	if (-e $ZipFileName)
		{
		$object->read($ZipFileName); 
		foreach $file (@files1) {$object->addFile($file);}
		foreach $file (@files2) {$object->addFile($file);}
		foreach $file (@files3) {$object->addFile($file);}
		$object->overwrite();
		}
	else
		{
		foreach $file (@files1) {$object->addFile($file);} 
		foreach $file (@files2) {$object->addFile($file);}
		foreach $file (@files3) {$object->addFile($file);}
		$object->writeToFileNamed($ZipFileName);
		}
	}
 if ($nuArgs == 5)
	{
	@files1 = <./$file1>;
	@files2 = <./$file2>;
	@files3 = <./$file3>;
    @files4 = <./$file4>;
	if (-e $ZipFileName)
		{
		$object->read($ZipFileName); 
		foreach $file (@files1) {$object->addFile($file);}
		foreach $file (@files2) {$object->addFile($file);}
		foreach $file (@files3) {$object->addFile($file);}
		foreach $file (@files4) {$object->addFile($file);}
		$object->overwrite();
		}
	else
		{
		foreach $file (@files1) {$object->addFile($file);} 
		foreach $file (@files2) {$object->addFile($file);}
		foreach $file (@files3) {$object->addFile($file);}
		foreach $file (@files4) {$object->addFile($file);}
		$object->writeToFileNamed($ZipFileName);
		}
	}
}
######################################################################
sub tarball
{
$Dos2unix_count = 0;
$PushList = $_[0];
$FTPUploadDir = "Upload_to";

		($pushlistfilename, $pushdir) = fileparse($PushList); 
#		$pushlistfilename =~ s/\..*//; 
		$pushlistfilename =~ s/\.[^\.]*$//;
		$pushlistfilename =~ s/\./_/g;
		print "Creating tar file for $pushlistfilename in $ExportDir.\n\n";    
		print $ER "Creating tar file for $pushlistfilename in $ExportDir.\n"; 
		
		$tarname = "$pushlistfilename"."_$tarcount".".tar";   
		$tartime = &PrintDate;
		print $ER "tar file creation START at $tartime named as $tarname.\n"; 
		print "tar file creation START at $tartime named as $tarname.\n\n";
############
## Code for Adding all exported folder entries with 777 permissions without any file entry
		if ( $Pushlist_count == 0) {
			chdir($ExportDir);
			$perm_list = "permission_pushlist.txt";
			@args = ("touch", $perm_list);
			system(@args) == 0 or die "touch @args failed: $?"; 
			`find . -type f >$perm_list` ;
			`echo "./$tarname" >>$perm_list` ;
			$current_export = "./";
			@args = ("tar", "-rf", $tarname, "-X", $perm_list, "--mode=777", $current_export );# "--no-recursion");
			system(@args) == 0 or die "tar @args failed: $?"; 
			$Pushlist_count++;
			unlink $perm_list;
			chdir($ScriptHome);
		}
## 
################		
open(TARFILE, $PushList) or die "Can't open pushlist file $PushList $!\n";  ### Opening Pushlist file and reading line by line
	while(my $LST1 = <TARFILE>){
				chdir($ExportDir);
                make_path($FTPUploadDir);
				chomp $LST1;
				@LSTval = split(' ',$LST1);
				$LST = @LSTval[0];
				chomp $LST;
				$LST =~ s/\\/\//g;
				$LST =~ s/^\///;
				
				$tarfilesize = -s $tarname;
#				if ($tarfilesize > 524288000)
				if ($tarfilesize > 209715200)
					{
						$tarendtime = &PrintDate;
						print $ER "tar file creation END at $tarendtime\n";
						print "tar file creation END at $tarendtime\n\n";
						@args = ("cp $tarname $FTPUploadDir");     
						system(@args) == 0 or die "system @args failed: $?"; 
						@args = ("mv $tarname $tarballloc");     
						system(@args) == 0 or die "system @args failed: $?"; 
						$tarcount++;
						$tarname = "$pushlistfilename"."_$tarcount".".tar"; 
						$tartime = &PrintDate;
						print $ER "tar file creation START at $tartime named as $tarname.\n"; 
						print "tar file creation START at $tartime named as $tarname.\n\n";
					}

			if (-e $LST) {
				if (-d $LST)
					{
							#$DLST = "$LST"."/*";
							opendir(DIR, "$LST");
							@FLST = grep(/.+\..+/,readdir(DIR));
							$LST =~ s/\/$//;
							foreach $my_file (@FLST){
							$DLST = "$LST"."/$my_file";
							if ($my_file =~/\.html$/ || $my_file =~/\.xml$/ || $my_file =~/\.txt$/ || $my_file =~/\.php$/|| $my_file =~/\.sh$/|| $my_file =~/\.css$/)
                                                	{
                                                       		@dosargs = ("dos2unix", $my_file );
                                                        	system("@dosargs 2>>Dos2UnixFile.log")== 0 or die "dos2unix @dosargs failed: $?";
                                                	}
		
							@args = ("tar", "-rf", $tarname, "--mode=777", $DLST);# "--no-recursion");
							system(@args) == 0 or die "tar @args failed: $?"; 
							}
							chdir($ScriptHome);	
					}
				else 
					{
						
					if ($LST =~/\.html$/ || $LST =~/\.xml$/ || $LST =~/\.js$/ || $LST =~/\.txt$/ || $LST =~/\.php$/ || $LST =~/\.sh$/ || $LST =~/\.css$/)
						{
							$Dos2unix_count++;
							@dosargs = ("dos2unix", $LST);
							system("@dosargs 2>>Dos2UnixFile.log")== 0 or die "dos2unix @dosargs failed: $?";
						}
 						@args = ("tar", "-rf", $tarname,"--mode=777", $LST);
						system(@args) == 0 or die "tar @args failed: $?"; 
						chdir($ScriptHome);
				}
					
				}
				else
				{
					print $ER "*** Given Path $LST does not exist.\n";
					print "*** Given Path $LST does not exist.\n\n";
					chdir($ScriptHome);
				}
			}
### Moving Dos2Unix log file to SVNLOGFile
	if ($Dos2unix_count != 0)
		{
		$DOs2UnixFileLog = "$tagname"."_Dos2UnixFile_log.txt";
		$Dos2UnixFile = "$ExportDir/"."Dos2UnixFile.log";
		 @args = ("mv", "$Dos2UnixFile", $DOs2UnixFileLog);
		system(@args) == 0 or die "system @args failed: $?"; 
		print $ER "\nTotal $Dos2unix_count files are converted from Dos to Unix Format\n\n";  
		print "\nTotal $Dos2unix_count files are converted from Dos to Unix Format\n\n";  
	
		}
	else {
		print $ER "\nNo Files having html/xml/js/txt/php/sh/css extension\n\n";
		print "\nNo Files having html/xml/js/txt/php/sh/css extension\n\n";
	    }	
### Closing Pushlist file.
	close(TARFILE);
	$tarendtime = &PrintDate;
	print $ER "tar file creation END at $tarendtime\n\n";
	print "tar file creation END at $tarendtime\n\n";

	chdir($ExportDir);
	if (-e $tarname) {
		@args = ("cp -f $tarname $FTPUploadDir");           
		system(@args) == 0 or die "system @args failed: $?"; 
		@args = ("mv $tarname $tarballloc");              
		system(@args) == 0 or die "system @args failed: $?";  
		$tarcount++; 
		chdir($ScriptHome);
	}
else
	{
		print $ER "**** ERROR: NOT able to CREATE TAR FILE for $pushlistfilename, BECAUSE NONE of the FILE/FOLDERS PATH MENTEIONED in PUSHLIST EXIST ****\n\n";
		print "**** ERROR: NOT able to CREATE TAR FILE for $pushlistfilename, BECAUSE NONE of the FILE/FOLDERS PATH MENTEIONED in PUSHLIST EXIST ****\n\n";
		chdir($ScriptHome);
	}
	chdir($ScriptHome);
### Moving pushlist file in root directory with complete status.
	move($PushList, "./complete.txt"); # Rename Pushlist file to complete.txt
	($pushlistfilename, $pushdir) = fileparse($PushList);
#	$pushlistfilename =~ s/\..*//;

	$pushlistfilename =~ s/\.[^\.]*$//;
	$pushlistfilename =~ s/\./_/g;
	($completepushfilename) = ("$pushlistfilename"."_complete.txt");
	@args = ("mv complete.txt $completepushfilename");
	system(@args) == 0 or die "system @args failed: $?"; 	
}
######################################################################
## Date and Time Function
sub PrintDate{
$CurrentTime = `date +%Y%m%d%H%M`;
chomp $CurrentTime;
return $CurrentTime;
}

#####################################################################
#sub ncftp{

#	$FtpPath = $_[0];
#	chdir($Ftpfileloc);
#	$userhome=$ENV{HOME};
#	$ncftplogloc="$userhome".'/.ncftp/spool';
#	if (-e $ncftplogloc) { rmtree($ncftplogloc); }

#	@ftpfiles = <./*>;	
#	foreach $ftpfile (@ftpfiles) 
#		{
#			@args = ("ncftpput", "-u", $ftpuser, "-p", $ftppassword, "-DD", "-bb", $ftphost, $FtpPath, $ftpfile);
#			system("@args"); 
#		}
#	chdir($ScriptHome);
#}
#####################################################################
 #sub ncftprestart{

#	$FtpPath = $_[0];
#	$Ftpfileloc = "$ExportDir"."/$FTPUploadDir";
#	chdir($Ftpfileloc);

 #	$userhome=$ENV{USERPROFILE};
#	$userhome=$ENV{HOME};
#	$ncftplogloc="$userhome".'/.ncftp/spool';
#	if (-e $ncftplogloc) { rmtree($ncftplogloc); }

#	@ftpfiles = <./*>;
#	foreach $ftpfile (@ftpfiles) 
#		{
			#@args = ("ncftpput", "-u", $ftpuser, "-p", $ftppassword, "-DD", "-bb", $ftphost, $FtpPath, $ftpfile);
#			system("@args"); 
#		}
#	chdir($ScriptHome);
#}
#########################################################################
#sub tarupload{
#		$userhome=$ENV{USERPROFILE};
	#	$userhome=$ENV{HOME};
	#	$ncftplogloc="$userhome".'/.ncftp/spool';
	#	$ncftplogfile="$userhome".'/.ncftp/spool'.'/log';
#
#		$FtpStart = &PrintDate;
#		print $ER "FTP Process Start at  $FtpStart \n";
#		print "FTP Process Start at  $FtpStart \n\n";
#		foreach  (1..5) # system args will execute five times.
#		{
#			sleep 5;
#			@args = ("ncftpbatch -d &");
#			system("@args");
#		}
#		chdir($ncftplogloc);
#		@ftpqueuefiles = <./*>;
#		$ftpqueuefilesnum = "$#ftpqueuefiles";
#		while($ftpqueuefilesnum != 0)
#			{
#				sleep 120;
#				@ftpqueuefiles = <./*>;
#				$ftpqueuefilesnum = "$#ftpqueuefiles";
#			}
#
#		chdir($ScriptHome);
#		$FtpEnd = &PrintDate;
#		print $ER "FTP Process End at  $FtpEnd \n\n";
#		print "FTP Process End at  $FtpEnd \n\n";
#		rmtree($Ftpfileloc);
#		$ftplogfilename = "$tagname"."_ftp_log.txt";
#		@args = ("cp -f $ncftplogfile $ftplogfilename");
#		system(@args) == 0 or die "system @args failed: $?";
#	}
##############################################################################

#############################################################################
sub sftpstart
{
$complete_path = "/opt/exports/SVN_Static_Export/$tagname";
$Ftpfileloc = "$complete_path"."/$FTPUploadDir";
#print $Ftpfileloc;
chdir($ScriptHome);
#@args =("cd $FTPUploadDir");
#system(@args) == 0 or die "system @args failed: $!";
@args = ("sh hmof_sftp.sh $Ftpfileloc");
system(@args) == 0 or die "system @args failed: $!";



}
#############################################################################
## Script Code

### Declaring Lock File
$lockfile = "autodeploy.lock";

### create / secure lock file, or die
if( -e $lockfile){
	print "*** INFO: autodeploy.lock FOUND. Sending ALERT Mail...\n";
	&SendMail ("Lock Found...", "$lockfile");
	exit;
}

### Opening lock file
open(LOCK, "> $lockfile");

### Declaring Required directory structure to run script
$workingdir = "SVN_Static_Export";

$qdir = "static_queue";

if (-d $qdir) ### Test the Queue Dir
 { 
### Processing all file exist in queue directory in for loop.
	@files = <$qdir/*>;

	$nooffiles = "$#files";

	if ($nooffiles < 0) 
		{
			print "*** ERROR: NO FILE EXIST in static_queue.\n\n";
			exit;
		}
	else
		{

	foreach $file (@files) 
		{
	
### Declaring Log/Error File
		$ErrorFile = "Static_content_ErrorFile.txt";

### Opening error file in append mode
		open ($ER, ">> $ErrorFile");

### Getting the User Name
		$PushStarttime = &PrintDate;
		print $ER "Script is executed by := $username from $host \($addr\) at $PushStarttime.\n\n";
		print "Script is executed by := $username from $host \($addr\) at $PushStarttime.\n\n";

### Printing file name in error and log file.
		print $ER "Processing $file \n\n";
		print "Processing $file \n\n";

### Opening deploy file and finding SVN path, tag name, FTP destination path and svn export path.
		$svnpath = "False";
		$tagname = "False";
		$destftppath = "False";
		$svnexportdir = "False";
		$deployfile = "True";
		$svnrvn= "False";

		open(DEPLOYFILE, $file) or die "Can't open deployment file $file $!\n"; 
		
### Assign the Value of SVN Path, TAG Name, FTP Path and SVN Export dir to False to validate this

		while($line = <DEPLOYFILE>){
		chomp $line;

####
			if ($line =~ /^SVNPATH:(.+)$/){ ($svnpath) = ($line =~ /^SVNPATH:(.+)$/);}
			if ($line =~ /^TAGNAME:(.+)$/){ ($tagname) = ($line =~ /TAGNAME:(.+)$/);}
			if ($line =~ /^FTPPATH:(.+)$/){ ($destftppath) = ($line =~ /^FTPPATH:(.+)$/);}
			if ($line =~ /^SVNEXPTPATH:(.+)$/){ ($svnexportdir) = ($line =~ /^SVNEXPTPATH:(.+)$/);}
			if ($line =~ /^SVNREVN:(.+)$/){ ($svnrvn) = ($line =~ /^SVNREVN:(.+)$/);}
			}

		close(DEPLOYFILE);		### Closing the DEPLOYFILE
			
			
### Update To Validate the SVN Path, TAG Name, FTP Path and SVNEXPORT Name 
if (($svnpath eq "False")||($tagname eq "False")||($destftppath eq "False") || ($svnexportdir eq "False")|| ($svnrvn eq "False")) {

if ($svnpath eq "False"){
					print $ER "*** ERROR: KEYWORD \"SVNPATH\" DOES NOT EXIST in $file. \n";
					print "*** ERROR: KEYWORD \"SVNPATH\" DOES NOT EXIST in $file. \n";
					$deployfile = "False";

					}
if($tagname eq "False"){
					print $ER "*** ERROR: KEYWORD \"TAGNAME\" DOES NOT EXIST in $file. \n";
					print "*** ERROR: KEYWORD \"TAGNAME\" DOES NOT EXIST in $file. \n";
					$deployfile = "False";
					}
if($destftppath eq "False") {
					print $ER "*** ERROR: KEYWORD \"FTPPATH\" DOES NOT EXIST in $file. \n";
					print "*** ERROR: KEYWORD \"FTPPATH\" DOES NOT EXIST in $file. \n";
					$deployfile = "False";
					} 
if ($svnexportdir eq "False") {
					print $ER "*** ERROR: KEYWORD \"SVNEXPTPATH\" DOES NOT EXIST in $file. \n";
					print "*** ERROR: KEYWORD \"SVNEXPTPATH\" DOES NOT EXIST in $file. \n";
					$deployfile = "False";
					}
if ($svnrvn eq "False") {
					print $ER "*** ERROR: KEYWORD \"SVNREVN\" DOES NOT EXIST in $file. \n";
					print "*** ERROR: KEYWORD \"SVNREVN\" DOES NOT EXIST in $file. \n";
					$deployfile = "False";
					}
			
if ($deployfile eq "False") {
					close $ER; 
					&SendMail ("*** ERROR: Define KEYWORDS DOES NOT EXIST in $file.", "$ErrorFile");
					unlink $ErrorFile;
					exit;
					}
}

if ($deployfile eq "True")	{
					print "*** $file Values: ***\n";
					print "SVNPATH:$svnpath\n";            
					print "TAGNAME:$tagname\n";            
					print "FTPPATH:$destftppath\n";        
					print "SVNREVN:$svnrvn\n\n";
					print $ER "*** $file Values: ***\n";
					print $ER "SVNPATH:$svnpath\n";
					print $ER "TAGNAME:$tagname\n";
					print $ER "FTPPATH:$destftppath\n";
					print $ER "SVNEXPTPATH:$svnexportdir\n\n";
					}

### Calculating Export directory
		 $ExportDir = "$workingdir/"."$tagname";
		 $SVNLogFile = "$tagname"."_SvnExport.log";

chdir($ExportDir);
$FTPUploadDir = "Upload_to";
if (-d $FTPUploadDir) {
	chdir($ScriptHome);
	print $ER "*** INFO: Script is starting from last FTP Upload failed.\n\n";
	print "*** INFO: Script is starting from last FTP Upload failed.\n\n";
	#&ncftprestart ("$destftppath");
	&sftpstart;
	### Uploading files on ftp 
	#&tarupload;                
}
else
	{
chdir($ScriptHome);
$TAGPushlist = "$tagname"."_pushlist";
if(! -d $TAGPushlist)
	{
			### If tag pushlist directory not exist, sending mail.                                      
			print $ER "Push List dir doesn't exist. \n";                                                
			print $ER "Dir name must be $TAGPushlist \n";                                               
			print $ER "Please create $TAGPushlist directory and reexecute the script.\n";  
			print "*** ERROR: PUSH LIST Directory $TAGPushlist DOES NOT EXIST. Sending ERROR Mail...\n";
			close $ER;                                                                                  
			&SendMail ("*** ERROR: PUSH LIST Directory $TAGPushlist DOES NOT EXIST.", "$ErrorFile");    
			unlink $ErrorFile;                                                                          
			exit;                                                                                       
	}

@Pushlistfiles = <$TAGPushlist/*>;

$noofpushlist = "$#Pushlistfiles";

if ($noofpushlist < 0)
	{
		print $ER "*** ERROR: No Pushlist exist in $TAGPushlist. \n";	
		print "*** ERROR: NO PUSHLIST EXIST in $TAGPushlist. Sending ERROR Mail...\n"; 
		close $ER;                                                                              
		&SendMail ("*** ERROR: NO PUSHLIST EXIST in $TAGPushlist.", "$ErrorFile");
		unlink $ErrorFile;                                                                      
		exit;
	}

### Creating working directory.
            make_path($workingdir);

### Checking export status of tag.		
		if (-d $ExportDir){
							### Pringting tag name status in error and log file.
							print $ER "$tagname is already exported. Starting Archive. \n\n";
							print "$tagname is already exported. Starting Archive. \n\n";
							### Specify tarball archive location
							$TarFtpStart = &PrintDate;
							$tarballloc = "$TarballArchive"."/$tagname"."_$TarFtpStart";  
							make_path($tarballloc);  
							### Geting the all push list file of a TAG
							@PushFiles = <$TAGPushlist/*>;
							foreach $PushTO (@PushFiles) {
							### Removing blank lines from pust lists.
							@args = ("perl", '-i.bak', '-n', '-e', '"print if /\S/"', $PushTO);
							system("@args");
							$backupfile = "$PushTO".".bak";
							unlink $backupfile;
							$tarcount = 1;
							### Calling tar ball method to create tar
							&tarball ("$PushTO");
								}
							}
		else
					{
					### Creating Export directory
                    make_path($ExportDir) or die " Cann't create Dir m3 !!! \n";
					$svnexportdir = ("$ExportDir/"."$svnexportdir");
#					$svnexportdir = ("c:\/scripts\/"."$svnexportdir");

					### Printing tagname and its export directory name in error and log file.
					print $ER "Exporting $tagname into $svnexportdir\n";
					print "Exporting $tagname into $svnexportdir\n\n";
					$SvnExportStart = &PrintDate;

					### Printing SVN export start time in error and log file.
					print $ER "SVN Export Start at $SvnExportStart\n";
					print "SVN Export Start at $SvnExportStart\n\n";
					### SVN export start and making log in SvnExport.log and failure error in SvnExport.err
					@args = ("svn", "export", "--force", "-r" , "$svnrvn", "--username", "dpant", "--password", "hHbBM7iq" , "$svnpath", "$svnexportdir");
					#@args = ("svn", "export", "--force", "--username", "asinghal", "--password", "mdxPEI31" , $svnpath, $svnexportdir);
					system("@args 1>SvnExport.log 2>SvnExport.err")== 0 or die "Tag revision number is wrong $svnrvn";
					$SvnExportEnd = &PrintDate;
					$SVNSize = `du -shx $ExportDir` ;
					print "SVN Size = $SVNSize \n\n";
					print $ER "SVN Size = $SVNSize \n\n";
					### If svn export successed then printing log in error and log file else sending status mail.
					if ($? > 0) 
					{
						print $ER "system @args failed: $?\n";
						print "system @args failed: $?\n";
						open ( my $Temp, "< SvnExport.err") or die " Cann't Open SvnExport.err file \n";
						while (my $Tmp = <$Temp>) 
						{
						print $ER "$Tmp";
						print $ER "**** SVN Export FAILED at $SvnExportEnd *****\n";
						print $ER "Script will re-try SVN export after 5 min.\n\n";
						print "**** SVN Export FAILED at $SvnExportEnd *****\n\n";  
						print "Script will re-try SVN export after 5 min.\n\n";     
						sleep 10;
						}
						close $Temp;
						remove_tree("SvnExport.err");
						remove_tree("SvnExport.log");
						$tmpval = "true";
						$resvntry = 1;
						while ( $tmpval ne "False" ) 
						{
							remove_tree("$ExportDir");
							$reSvnExportStart = &PrintDate;
							print $ER "*** Re-Try $resvntry ***\n\n";
							print "*** Re-Try $resvntry ***\n\n";    
							print $ER "SVN Export Re-Start at $reSvnExportStart\n\n";
							print "SVN Export Re-Start at $reSvnExportStart\n\n"; 
							### SVN export start and making log in SvnExport.log and failure error in SvnExport.err                            
							##@args = ("svn", "export", "--force", "--username", "dpant", "--password", "hHbBM7iq" , $svnpath, $svnexportdir); 
					        @args = ("svn", "export", "--force", "-r" , "$svnrvn", "--username", "dpant", "--password", "hHbBM7iq" , $svnpath,"$svnexportdir");;
							system("@args 1>SvnExport.log 2>SvnExport.err")== 0 or die "Tag revision number is wrong $svnrvn";                                                                   
							if ($? == 0)
							{ 
								$tmpval = "False"; 
								@args = ("mv", "SvnExport.log", $SVNLogFile);                    
								system(@args) == 0 or die "system @args failed: $?";              
								print "*** SVN Export Log in saved in $SVNLogFile *** \n\n";      
								print $ER "*** SVN Export Log is in attached $SVNLogFile *** \n"; 
								remove_tree("SvnExport.err"); 
								$reSvnExportEnd = &PrintDate;
								### Printing SVN export end time in error and log file. 
								#$SVNSize = system("du -shx $ExportDir");	
								print $ER "SVN Export completed at $reSvnExportEnd\n\n";  
								print "SVN Export completed at $reSvnExportEnd\n\n";      
							}
							else 
							{ 
								$reSvnExportEnd = &PrintDate;
								print $ER "system @args failed: $?\n";                                                  
								open ( my $Temp, "< SvnExport.err") or die " Cann't Open SvnExport.err file \n";        
								while (my $Tmp = <$Temp>)                                                               
								{                                                                                       
								print $ER "$Tmp";                                                                     
								print "**** SVN Export FAILED at $reSvnExportEnd *****\n\n";                            
								print "Script will re-try SVN export after 5 min.\n\n"; 
								print $ER "**** SVN Export FAILED at $SvnExportEnd *****\n";  
								print $ER "Script will re-try SVN export after 5 min.\n\n";     
								sleep 300;                                               
								}
								close $Temp;                 
								remove_tree("SvnExport.err");
								remove_tree("SvnExport.log");
								$resvntry = $resvntry + 1;
							}

						if ( $resvntry > 5 ) 
							{
							print $ER "**** Maximum SVN Export Re-Try Reached. May be SVN Server is down. *****\n";                                
							print $ER "Please remove $tagname from $workingdir and autodeploy.lock\n"; 
							print $ER "Restart the script execution\n\n";                                
							close $ER;                                                       
							print "*** Maximum SVN Export Re-Try Reached. Sending ERROR Mail...\n";  
							&SendMail ("*** ERROR - Maximum SVN Export Re-Try Reached. ***", "$ErrorFile");   
							unlink $ErrorFile; 
							exit;                                                            
							}
					}
					}
					else
					{
						@args = ("mv", "SvnExport.log", $SVNLogFile);   
						system(@args) == 0 or die "system @args failed: $?";  
						print "*** SVN Export Log in saved in $SVNLogFile *** \n\n";
						print $ER "*** SVN Export Log is in attached $SVNLogFile *** \n";
						remove_tree("SvnExport.err");
						### Printing SVN export end time in error and log file.
						print $ER "SVN Export completed at $SvnExportEnd\n\n";
						print "SVN Export completed at $SvnExportEnd\n\n";
					}
					
					### Specify tarball archive location
					$TarFtpStart = &PrintDate;
					$tarballloc = "$TarballArchive"."/$tagname"."_$TarFtpStart";  
					make_path($tarballloc);  
					### Geting the all push list file of a TAG
					@PushFiles = <$TAGPushlist/*>;
					foreach $PushTO (@PushFiles) {
						### Removing blank lines from pust lists.
						@args = ("perl", '-i.bak', '-n', '-e', '"print if /\S/"', $PushTO); 
						system("@args");                                                    
						$backupfile = "$PushTO".".bak";                                     
						unlink $backupfile; 
						$tarcount = 1;
						&tarball ("$PushTO");                         
							}
					}
		$Ftpfileloc = "$ExportDir"."/$FTPUploadDir";
		chdir($Ftpfileloc);
		@ftpfiles = <./*>;
		$noftpfl = "$#ftpfiles";
		if ($noftpfl >= 0) 
			{
				### Calling FTP function to start FTP upload.
				#&ncftp ("$destftppath"); 
				&sftpstart;
				### Uploading files on ftp 
				#&tarupload;                
			}
		else
			{
				print $ER "*** INFO: No tar file created to FTP Upload.\n\n";   
				print "*** INFO: No tar file created to FTP Upload.\n\n";  
				chdir($ScriptHome);
				rmtree($Ftpfileloc);
			}
}

					### moving DEPLOYFILE to root directory with complete status.
					move($file, "./complete.txt"); 
					($deployfilename, $queuedir) = fileparse($file);
					$deployfilename =~ s/\..*//;
					($completefilename) = ("$deployfilename"."_complete.txt");
					@args = ("mv", "complete.txt", $completefilename);
					system(@args) == 0 or die "system @args failed: $?"; 
					
					### Closing error and log file and renaming log file with tagname_log.txt and mailing it.
					$PushEndtime = &PrintDate;
					print $ER "PUSH Completed Successfully for $tagname at $PushEndtime.";
					close $LG;
					close $ER;
					sleep 5;
					($completelogfilename) = ("$tagname"."_log.txt");
					@args = ("mv", "Static_content_ErrorFile.txt", $completelogfilename);
					system(@args) == 0 or die "system @args failed: $?"; 
					if (-e "$SVNLogFile") {system("unix2dos *_log.txt >/dev/null 2>/dev/null"); &CreateZip ("Status.zip", "*_log.txt", "$SVNLogFile");} 
					else { &CreateZip ("Status.zip", "*_log.txt");}
					print "*** INFO: PUSH Completed Successfully for $tagname at $PushEndtime. Sending Mail...\n";
					&SendMail ("Push Complete for $tagname.", "Status.zip");
					unlink "Status.zip";
					unlink $LogFile;
					remove_tree("$TAGPushlist");
					
					$logtime = &PrintDate;
					$logzipfile = "$tagname"."_$logtime".".zip";
					if (-e "$SVNLogFile") {system("unix2dos *_log.txt *_complete.txt >/dev/null 2>/dev/null"); &CreateZip ("$logzipfile", "*_log.txt", "*_complete.txt", "$SVNLogFile"); unlink "$SVNLogFile"; }
					else {system("unix2dos *_log.txt *_complete.txt >/dev/null 2>/dev/null");&CreateZip ("$logzipfile", "*_log.txt", "*_complete.txt");}
					@args = ("rm -f *_log.txt *_complete.txt");
					system(@args) == 0 or die "system @args failed: $?"; 
					@args = ("mv $logzipfile $LogsArchive");     
					system(@args) == 0 or die "system @args failed: $?";  
 	}
}
					### Closing and removing lock file.
 					close LOCK;
					unlink($lockfile);	
 }
else 
  { 
	### If queue directory does not exist sending mail.
	$queueerror = "queueerror.log";
	open($qu, "> $queueerror");
	print $qu "$qdir Doesn't Exists....\n";
	print $qu "Nothing to Do....\n";
	close $qu;
	print "*** ERROR: static_queue DIRECTORY DOES NOT EXIST. Sending ERROR Mail...\n";
	&SendMail ("static_queue Directory does not exist.", "$queueerror");
	unlink $queueerror;
	close LOCK;
	unlink($lockfile);
	exit;
  }

