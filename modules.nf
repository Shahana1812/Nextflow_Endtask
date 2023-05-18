
//sra-toolkit, user repository: home/cq/NGS/cq-examples/exam/SRA_data
nextflow.enable.dsl = 2

params.accession = null
params.outdir = "SRA_data1" 

process prefetch {

  storeDir "${params.outdir}"

  container "https://depot.galaxyproject.org/singularity/sra-tools%3A3.0.3--h87f3376_0"

  input:
    val accession

  output:
    path "sra/${accession}.sra" 

  script:
    """
    prefetch $accession 
    """
}


process convertfastq {
    //set directory where you want your files to be dumped
    storeDir "${params.outdir}/sra/${accession}_fastq/raw_fastq"

    container "https://depot.galaxyproject.org/singularity/sra-tools%3A3.0.3--h87f3376_0"

    input:
        val accession
        path srafile

    output:
        path "*.fastq", emit: fastqfiles // telling the interpreter to expect a file with this path structure as output channel contents

    script:
        """
        fastq-dump --split-files ${srafile}
        """
}

process fastqc {
    //directives
    // (No choice here, must use publishDir)
    publishDir "${params.outdir}/sra/${params.accession}_fastq/fastqc_results/"
    container "https://depot.galaxyproject.org/singularity/fastqc:0.12.1--hdfd78af_0"

    input:
    // Create one channel for handling .fastq file
      path fastqfiles

    output:
    // (Expected output documented online)
    // Goal: handle .html and .zip files
    // How do we reach that?
      path "*.html"
      path "*.zip"


    script:
    //      fastqc ourfiles 
      """
      fastqc ${fastqfiles}
      """
}

process fastp {
  publishDir "${params.fastqdir}", mode: 'copy', overwrite: true

  container "https://depot.galaxyproject.org/singularity/fastp:0.20.1--h8b12597_0"

  input:
    val accession
    path fastqfiles

  output: // one is fine if you are not piping this to something else
    path "fastp_fastq/*.fastq"
    path "fastp_report"

  script:
  // we have to set input, output, .html output and .json output, to be safer
      if(fastqfiles instanceof List) {
      """
      mkdir fastp_fastq
      mkdir fastp_report
      fastp -i ${fastqfiles[0]} -I ${fastqfiles[1]} -o fastp_fastq/${fastqfiles[0].getSimpleName()}_fastp.fastq -O fastp_fastq/${fastqfiles[1].getSimpleName()}_fastp.fastq -h fastp_report/fastp.html -j fastp_report/fastp.json
      """
    } else {
      """
      mkdir fastp_fastq
      mkdir fastp_report
      fastp -i ${fastqfiles} -o fastp_fastq/${fastqfiles.getSimpleName()}_fastp.fastq -h fastp_report/fastp.html -j fastp_report/fastp.json
      """
    }
}