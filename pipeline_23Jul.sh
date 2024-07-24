#!/usr/bin/bash


## You can run this script by typing the following into your terminal (without the ## ):
## sh pipeline.sh

## You need to run this script in the same folder as where your files are!
## Rememebr how to find that??
## Check the PDF from the tutorial!


## What files you need in your directory: 
## 1) Your raw fastqs -- as many samples as you want -- that's the point of automating with a bash script
## Eg S1_R1.fastq, S1_R2.fastq, S2_R1.fastq, S2_R2.fastq, S3_R1.fastq, S3_R2.fastq
## 2) Nextera adapter fasta -- rememberm for Trimmomatic?
## 3) Reference fasta -- Whatever you want to map against, as a fasta!
## 4) THIS SCRIPT!


## We're going to use something called a for-loop to loop through each sample
## And then for each sample, we're going to run the exact sample pipeline we ran as individual steps




## for every file in the list of files that matches this pattern -- remember the * wildcard?
for f in *R1.fastq; do

## we're going to do whatever come after this to every file that matches the filename pattern

	## echo prints the file name to the screen
	## the file name is now stored in the variable f
	## so, to access the variable with bash scripting, we'll use the notation ${}
	## so variable f is ${f}

	echo ${f}

	## we want to extract the sample ID from the file name

	## let's create a new variable to store the sample ID in
	## we'll use s_ID=$() to create a new variable called s_ID 

	## we're going to print out our file name saved as the variable ${f} with the command echo
	## Then we're going to replace the rest of the text in the file name

	## remember, our file name stored in ${f} is e.g. S1_R1.fastq
	## so, if we want the sample number S1 we need to replace the "_R1.fastq" part of the name
	## but we need to do it in a way that will replace R1.fastq and R2.fastq
	## so we're going to use a few more wild cards!
	## The regular expression "(.*)" indicates everything possible after the pattern match
	## so, for "/_(.*)", this is going to be: replace everything after the underscore!
	## We're going to use a terminal command to replace the text in the file name called sed!
	## so in the following step, we create a new variable called s_ID
	## and then to that variable we save the filename stored in f, but before that, we replace
	## everything after the underscore in the filename
	##so, sed is the command that does find and replace
	## and the command structure is "s/replace_this/with_that/g" -- the s means substitute
	## and the g means global aka replace it everywhere
	## So, we're replacing the pattern "everything after an underscore" with nothing, so we're basically deleting it 
	## We're deleting everything after the underscore because we're replacing it with nothing 
	## we know that because there's nothing between the second pair of slahes!

	s_ID=$(echo ${f} | sed -E "s/_(.*)//g")

	## okay, let's see if that works by printing out the sample ID
	echo ${s_ID}

	## Okay good, now we have the sample ID saved as a variable called s_ID
	## WE NEED to have our sample saved because we want to run this script in a folder were all of our fastqs are saved. 
	## BUT we want to run the pipeline on each sampled in sequence respectively
	## So we save the sample ID so we

	## So now we can start running our pipeline, but we can specify which samples using this variable!


	## Run fastqc to assess the read quality of our fasts -- see tutorial
	## BUT SPECIFICALLY the fastq files of our sample ID saved in s_ID!
	fastqc ${s_ID}_R1.fastq
	fastqc ${s_ID}_R2.fastq

	## Remember what output we expect from this step? -- see tutorial
	## let's create a new directory to move our fastqc quality reports there
	## We're going to use mkdit like last time
	## BUT we're going to use the variable with the sample ID to make a folder with our sample ID in
	## We want to make a folder called e.g S1_fastqc_report or S2_fastqc_report 
	## So we're going to use the vairable we created ${s_ID} with the sample ID in it
	mkdir ${s_ID}_fastqc_report

	# ## Now let's move our fastqc output to this new folder -- see tutorial for what these files are
	mv *.html ${s_ID}_fastqc_report
	mv *.zip ${s_ID}_fastqc_report

	## Okay, now we can trim and filder our fastq files
	## All of these steps and input and output files are exactly the same as the tutorial
	## So check the PDF if you cannot remember what they are!
	## Now, we'll run trimmomatic with the exact same command as in the tutorial
	## EXCEPT now instead of S1 we have the variable named ${s_ID}
	## BUT we have the sample ID e.g. S1 saved in the variable ${s_ID}
	## So ${s_ID}_R1.fastq should be S1_R1.fastq if variable ${s_ID} == S1!
	## Again, it's the exact same command as the tutorial -- so see PDF for full details

	trimmomatic PE -threads 3 ${s_ID}_R1.fastq ${s_ID}_R2.fastq ${s_ID}_R1_P.fastq ${s_ID}_R1_UP.fastq ${s_ID}_R2_P.fastq ${s_ID}_R2_UP.fastq ILLUMINACLIP:Nextera_transpose.fasta:2:30:10 SLIDINGWINDOW:4:20 MINLEN:50 &> ${s_ID}_trimsummary.txt

	## Okay, so now we've got our trimmed read output
	## Remember -- see tut -- we have 4 output fastqs -- 2 paired, 2 unpaired (reverse and forward reads from paired end sequencing)

	## I'm also going to make a random folder called intermediates
	## and I'm just going to move all the random files there that some of the programs produce, so we have them in one place

	mkdir ${s_ID}_intermediates

	## For example, I'm going to save the Trimmomatic text file log there that we created by redirecting the screen output

	mv ${s_ID}_trimsummary.txt ${s_ID}_intermediates

	## Okay, now we can map our paired, filtered reads to out reference!
	## Again, see the tutorial PDF for the theory

	## First thing we need to do? Index our reference for bwa

	bwa index NC003310.fasta

	## Now we can map! 
	## Remember, ${s_ID}_R1_P.fastq is the same as S1_R1_P.fastq IF the ${s_ID} variable is S1!
	## But if we assigned ${s_ID} to S2, because that's the file we're working with, then ${s_ID}_R1_P.fastq will be S2_R1_P.fastq 
	## and were generating the bam ${s_ID}.bam
	## which will be S1.bam if ${s_ID} == S1
	## but will be S2.bam if ${s_ID} == S2 etc

	bwa mem -t 3 NC003310.fasta ${s_ID}_R1_P.fastq ${s_ID}_R2_P.fastq | samtools view -u -@ 3 - | samtools sort -@ 3 -o ${s_ID}.bam

	## Okay, now that we have our bam we're done with our fastqs


	## Now, let's generate our coverage files

	samtools depth ${s_ID}.bam > ${s_ID}_coverage.tsv

	## Let's make an output folder

	mkdir ${s_ID}_output

	## And move our coverage file there, as it is important!

	mv ${s_ID}_coverage.tsv ${s_ID}_output


	## Now, let's call consensus, like we did in the tutorial with samtools and ivar

	samtools mpileup -A -d 0 -Q 0 -B ${s_ID}.bam | ivar consensus -p ${s_ID} -t 0.5 -m 10

	## We can move our consensus sequence in the fasta file to our output folder

	mv ${s_ID}.fa ${s_ID}_output

	## Okay, now let's call variants like we did in the tut!

	samtools mpileup -aa -A -B -Q 0 ${s_ID}.bam | ivar variants -p ${s_ID}_var -t 0.03 -m 10 -r NC003310.fasta

	## Let's move the variant calling output to our output folder!

	mv ${s_ID}_var.tsv ${s_ID}_output 


	## We're basically done with all of the steps in our pipeline for this sample
	## So let's just clean up before we move to the next sample

	## Let's move our bam to out output folder so we can do bam diagnoses if anything looks strange with out consensus or variant calls

	mv ${s_ID}.bam ${s_ID}_output

	## ivar produces this random file *_qual.txt about the quality scores for each base
	## So, let's move it to the intermediates folder (just in case we randomly need it!)

	mv ${s_ID}*qual.txt ${s_ID}_intermediates

	## Okay! Now let's make a folder with the name of our sample
	## Remenber, this is stored in the variable ${s_ID}

	mkdir ${s_ID}/

	# Now, let's move ALL of the folders we just made that start with our sample to this folder

	mv ${s_ID}_*/ ${s_ID}/

	## Basically, this will create a folder with ALL files and folder for that first sample in it
	## So at the end of this part of the loop, we're ready to move on to the next sample
	## And run everything all over again for e.g. S2!

	## So let's clean up a bit

	## LEt's compress our original raw fastqs

	gzip ${s_ID}*.fastq

	## Let's also compress our unpaired reads produced by Trimmomatic -- see tut for details

	gzip ${s_ID}*_UP.fastq

	## Let's make a new directory to move these read files to as we're done with them

	mkdir ${s_ID}_fastqs

	## Let's move the compressed fastq files to the new folder

	mv ${s_ID}*.gz ${s_ID}_fastqs
	
	## So, let's compress them to save space with gzip

	gzip ${s_ID}*_P.fastq 

	## And then move them to our fastqs folder
	## remember ${s_ID}_fastqs will be S1_fastqs or S2_fastqs etc

	mv ${s_ID}*.gz ${s_ID}_fastqs


done

## This is the end of our loop. SO basically, that pipeline up top will run for each sample
## And then when it's done, we'll clean up the remaining files:

mkdir references
mv NC003310.fasta.* references
mv Nextera_transpose.fasta references

