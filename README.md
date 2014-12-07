This is a tool for auto align a corpus using HTK toolkit.I impelemented it for my research work,and I'd like to share it to help those 
who are not familiar with this.
PS:It is for mandarine,if you want to use it for other languages,you need to change the dict file in general directory for your language.




Requirements
--------------------------------------------
HTK  http://htk.eng.cam.ac.uk/  
Perl5.8  
GNU make  



Directory
--------------------------------------------
wav :wav files  
script : perl script to do aligning  
general : dictionary transcription and other general files  
cofig: config files for HTK  


Tutorial
---------------------------------------
 step 1(preparation):  
 1 Edit line 2 in script/align.pl,specify your HTK PATH  
 2 Put your wav files in wav directory  	
 3 Creat a file named words.mlf in general directory,this file should include the transcription of your utterances and in this format:  
	 #!MLF!#  
	"*/201.lab"  
	jiu  
	shi  
	xia  
	yu  
	ye  
	qu  
	.  
	"*/202.lab"  
	wo  
	ma  
	shang  
	na  
	lai  
	.	  
  you can generate this file with shell, perl or other script.  
step 2(run):  
	execute make in project directory ,and then wait...  
	$ make  
                
