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
        pynome -d ${params.output.pynome_data_dir} -c -m
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

process calculate_memory {

    input:
        path index_file from INDEX_JOB_FILE_LIST

    output:
       set file(index_file), stdout into INDEX_JOB_SET	

    script:
        """
        tax_id=`head -n 1 $index_file`
        assembly=`tail -n 1 $index_file`
        num_seqs=`grep -c ">" ${params.output.pynome_data_dir}/\$tax_id/\$assembly/*.fa`
        size=`ls -lk ${params.output.pynome_data_dir}/\$tax_id/\$assembly/*.fa | awk '{print \$5}'`
        python -c "print(max(4, (\$size * 2)/1000000000 + 1))" | perl -p -e 's/\n//'
        """

}


process index_genome {
    label "index_genome"
    memory "$memory_limit GB"

    input:
        set file(index_file), val(memory_limit) from INDEX_JOB_SET

    script:
        """
        pynome -d ${params.output.pynome_data_dir} -n ${task.cpus} -i -f $index_file
        """
}
