nextflow.enable.dsl = 2

params.accession = null
params.outdir = "SRA_data1"
params.fastqdir = "SRA_data1/sra/${params.accession}_fastq/"

// include for pre-written processes
include { prefetch } from "./modules"
include { convertfastq } from "./modules"
include { fastqc } from "./modules"
include { fastp } from "./modules"

// The workflow executes 4 processes in sequence:
// (1) download raw data from SRA (prefetch)
// (2) generate .fastq file(s) using our downloaded data (fastq-dump)
// (3) generate fastqc report(s) using our .fastq files (fastqc)
// (4) trimming the raw fastq files (fastp)


workflow {
    srafile = prefetch(Channel.of(params.accession))
    converted = convertfastq(Channel.of(params.accession), srafile)
    converted_flat = converted.flatten()
    reports_channel = Channel.empty()
    fastqc_outputchannel = fastqc(converted_flat)
    reports_channel = reports_channel.concat(fastqc_outputchannel)
    reports_channel_collected = reports_channel.collect()
    fastp(Channel.of(params.accession), reports_channel_collected)

}