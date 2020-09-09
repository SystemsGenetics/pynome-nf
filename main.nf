#!/usr/bin/env nextflow

/**
 * ========
 * Pynome-nf
 * ========
 *
 * Authors:
 *  + Stephen Ficklin
 *  + Josh Burns
 *
 * Summary:
 *   A workflow for execution of Pynome: performs automated crawling, mirroring and indexing of public whole genomes.
 */


println """\
General Information:
--------------------
  Profile(s):                 ${workflow.profile}
  Container Engine:           ${workflow.containerEngine}

Input Files:
-----------------
  Species List:               ${params.input.species}

Output Parameters:
------------------
  Output directory:           ${params.output.pynome_data_dir}
"""

process crawl_and_mirror {

    output:
        stdout CRAWL_AND_MIRROR_OUT

    script:
        """
        pynome -d ${params.output.pynome_data_dir} -c -m -t carnosa
        """
}

process create_index_jobs {
    input:
        val out from CRAWL_AND_MIRROR_OUT

    output:
        path '*.txt' into INDEX_JOB_FILES

    script:
        """
        pynome -d ${params.output.pynome_data_dir} -I
        """
}

INDEX_JOB_FILES.flatMap().set {INDEX_JOB_FILE_LIST}

process index_genome {
    input:
        path index_file from INDEX_JOB_FILE_LIST
    script:
        """
        pynome -d ${params.output.pynome_data_dir} -i -f $index_file
        """
}
