#HTK工具
$HTK="/usr/local/bin";
$HCopy="$HTK/HCopy";
$HHEd="$HTK/HHEd -A -T 1 -D";
$HERest=" $HTK/HERest  -A -D  -T 1 ";
$HCompV="$HTK/HCompV -A -D -T 1 -C config/train.cfg";
$HInit="$HTK/HInit -A -D -T 1 -C config/train.cfg";
$HRest="$HTK/HRest -A -D -T 1 -C config/train.cfg";
$HVite="$HTK/HVite";
##全局参数设置
my $vecsize=39;
my $featuretype="MFCC_0_D_A";
my $nState=5;
my $nIter=10;
#
#
#流程控制
my $INIT=1;
my $EXTRACT=1;
my $MK_PROTO=1;
my $FLAT=1;
my $EMBEDED0=1;

my $ALIGN1=1;

my $REINIT=1;

my $EMBEDED1=1;
my $ALIGN=1;


if($INIT)
{
mkdir "lab",0755;
print "make phone level transcrition\n";
system("$HTK/HLEd -l lab -d general/dict  general/mkphones.hed general/words.mlf");


print "generate SCP file\n";
open SCP,">general/hcopy.scp" or die "can't open";
my @wavs=<wav/*.wav>;
for (@wavs)
{
	my $name=`basename $_ .wav`;
	chomp $name;
	if(-e $_ and -e "lab/$name.lab")
	{
		print SCP "$_ mfc/$name.mfc\n";
	}
}
system('awk \'{print $2}\' general/hcopy.scp >general/train.scp');


}

if($EXTRACT)
{
print "Extract features\n ";
mkdir "mfc",0755;
system("$HCopy -T 1 -C config/hcopy.cfg -S general/hcopy.scp");
}

if($MK_PROTO){
print "make proto hmm \n";
mkdir "mmf",0755;
open PROTO,">mmf/proto" or die "can't open $!";
print PROTO "~o <VecSize> $vecsize<$featuretype>\n";
print PROTO "~h \"proto\"\n";
print PROTO "<BeginHMM>\n";
print PROTO "<NumStates> $nState\n";
for(my $i=2;$i<$nState;$i++)
{
	print PROTO "<State> $i\n";
	
	print PROTO "<Mean> $vecsize\n";
	for(my $j=0;$j<$vecsize-1;$j++)
	{
		print PROTO "0.0 ";
	}
	print PROTO "0.0\n";
	print PROTO "<Variance> $vecsize\n";
	for(my $j=0;$j<$vecsize-1;$j++)
	{
		print PROTO "1.0 ";
	}
	print PROTO "1.0\n";
}
print PROTO "<TransP> $nState\n";
   print PROTO "    ";
   for ( $j = 1 ; $j <= $nState  ; $j++ ) {
      print PROTO "1.000e+0 " if ( $j == 2 );
      print PROTO "0.000e+0 " if ( $j != 2 );
   }
   print PROTO "\n";
   print PROTO "    ";
   for ( $i = 2 ; $i <= $nState -1 ; $i++ ) {
      for ( $j = 1 ; $j <= $nState  ; $j++ ) {
         print PROTO "6.000e-1 " if ( $i == $j );
         print PROTO "4.000e-1 " if ( $i == $j - 1 );
         print PROTO "0.000e+0 " if ( $i != $j && $i != $j - 1 );
      }
      print PROTO "\n";
      print PROTO "    ";
   }
   for ( $j = 1 ; $j <= $nState ; $j++ ) {
      print PROTO "0.000e+0 ";
   }
   print PROTO "\n";

   # output footer
   print PROTO "<EndHMM>\n";


}


system("$HCompV  -M mmf -S general/train.scp -m -f 0.001  mmf/proto");

if($FLAT)
{
open LIST,"<general/phoneme.lst" or die "can't open $!";
mkdir "mmf/flat",0755;
while(<LIST>)
{
	chomp;
	my $phone=$_;
	open( SRC, "mmf/proto" )       || die "Cannot open $!";
            open( TGT, ">mmf/flat/$phone" ) || die "Cannot open $!";
            while ( $str = <SRC> ) {
               if ( index( $str, "~h" ) == 0 ) {
                  print TGT "~h \"$phone\"\n";
               }
               else {
                  print TGT "$str";
               }

}
}
}
my $nHmm1=3;
if($EMBEDED0)
{
	system("$HHEd -d mmf/flat -w mmf/monophone.mmf general/lvf.hed general/phoneme.lst");
	print "fix silence\n";
#	system("$HHEd -H mmf/monophone.mmf general/sil.hed general/phoneme.lst");
	mkdir "mmf/hmm0",0755;
	system("cp mmf/monophone.mmf mmf/hmm0/monophone.mmf");
	for(my $i=1;$i<=$nHmm1;$i++)
	{
	mkdir "mmf/hmm$i",0755;
	$ii=$i-1;
	print "HRest for monophones ,$i iteration\n";
	system("$HERest -v 0.00001 -H mmf/hmm$ii/monophone.mmf -t 1500 100 5000 -L lab -M mmf/hmm$i general/phoneme.lst -S general/train.scp");
	}

}

if($ALIGN1)
{
mkdir "lab2",0755;
system("$HVite -a -b sil  -D -T 1 -A -m -l lab2  -y lab -o SW -I   general/words.mlf -S general/train.scp -H mmf/hmm$nHmm1/monophone.mmf  general/dict  general/phoneme.lst");
}


if($REINIT)
{
	mkdir "mmf/hinit",0755;
	mkdir "mmf/hrest",0755;
	system ("head -n 3 mmf/proto >mmf/init.mmf");
	system ("cat mmf/vFloors >>mmf/init.mmf");
	open LIST,"<general/phoneme.lst" or die "can't open $!\n";
	for my $phone(<LIST>)
	{
		chomp $phone;
		system("$HInit -H mmf/init.mmf -M mmf/hinit -L lab2 -S general/train.scp -l $phone -o $phone mmf/proto");
		system("$HRest -H mmf/init.mmf -M mmf/hrest -L lab2 -S general/train.scp -l $phone  mmf/hinit/$phone");
	}
}

my $nHmm2=5;
if($EMBEDED1)
{
	print "fix silence\n";
#	system("$HHEd -H mmf/monophone.mmf general/sil.hed general/phoneme.lst");
	for(my $i=$nHmm1+1;$i<=$nHmm1+$nHmm2;$i++)
	{
	mkdir "mmf/hmm$i",0755;
	$ii=$i-1;
	print "HRest for monophones ,$i iteration\n";
	system("$HERest -v 0.00001 -H mmf/hmm$ii/monophone.mmf -t 100 100 5000 -L lab -M mmf/hmm$i general/phoneme.lst -S general/train.scp");
	}

}

if($ALIGN)
{
mkdir "lab3",0755;
for(my $i=$nHmm1+1;$i<=$nHmm1+$nHmm2;$i++)
{
mkdir "lab3/$i",0755;
system("$HVite -a -b sil  -D -T 1 -A -m -l lab3/$i  -y lab -o SW -I   general/words.mlf -S general/train.scp -H mmf/hmm$i/monophone.mmf  general/dict  general/phoneme.lst");
for (<lab3/$i/*.lab>)
{
system("HLEd -l lab3/$i general/delspbeforsil.hed $_\n");
}
}
}
