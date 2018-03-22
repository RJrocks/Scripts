use lib "/home/deepak/perl5/lib/perl5";
use Spreadsheet::XLSX;
use Spreadsheet::Read;
$platformtype = $ARGV[1];
if ( $ARGV[0] eq '') {
	print "Enter Manifest File Name: ";
chomp($xlsxfile = <STDIN>);
}
else {
	$xlsxfile = $ARGV[0];
}

my $xlsx = ReadData ("$xlsxfile");
chomp($xlsx);
$lines = 3;
$CntType = $xlsx->[2]{"A$lines"};
while($CntType  ne ''){
$CntType = $xlsx->[2]{"A$lines"};
if ($CntType eq 'static'){
$spushlist = $xlsx->[2]{"B$lines"};
$spushlistrevno=$xlsx->[2]{"C$lines"};
$spushlisttag=$xlsx->[2]{"D$lines"};
$spushlisttagrevno=$xlsx->[2]{"E$lines"};
$last_element = substr($spushlisttag, rindex($spushlisttag, '/') + 1);

print "\n$spushlist\n$spushlistrevno\n$spushlisttag\n$spushlisttagrevno\n$last_element\n";

my @tagarray= split('/', $spushlisttag);
$tagname;
$tagcount= scalar @tagarray;
if($tagarray[$tagcount] eq '')
{
$tagname=$tagarray[$tagcount -1];
}
else
{
$tagname=$$tagarray[$tagcount];
}

print "\n tagname is : $tagname \n ";

chdir "/home/deepak/StaticData/";
$create_folder=$tagname."_pushlist";
$create_txt =$tagname."_details.txt";
print "$create_folder";
mkdir "$create_folder";
chdir "$create_folder";
system("svn export --force --username ogallen --password Shae7Shu  -r $spushlistrevno  --depth=files $spushlist") == 0 or die "getting error while exporting  svn pushlist"; 
chdir "/home/deepak/StaticData/static_queue";

if($platformtype eq 'HMOF')
{
$write_data="SVNPATH:$spushlisttag\nTAGNAME:$tagname\nFTPPATH:/content/my.hrw.com/\nSVNEXPTPATH:/\nSVNREVN:$spushlisttagrevno";
}

if($platformtype eq 'TCK')
{
$write_data="SVNPATH:$spushlisttag\nTAGNAME:$tagname\nFTPPATH:/content/www-k6.thinkcentral.com/\nSVNEXPTPATH:/\nSVNREVN:$spushlisttagrevno";
}

print "$write_data\n";
open($data,">> $create_txt");
print $data $write_data;
close($data);

}
$lines++;
}
chdir "/home/deepak/saurabh/static_tag/";
system("sh statictag.sh $platformtype $create_folder")== 0 or die"problem to create tar and copy file to server";

#system("sh statictag.sh") == 0 or die "problem to create tar and copy file to server";




