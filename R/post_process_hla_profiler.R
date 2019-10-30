#' ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#' post_process_hla_profiler
#' ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#' @title post_process_hla_profiler
#'
#' @description
#' Joins individual sample files into one tsv file.
#'
#' @param input_file_paths Character vector of paths to the pipeline output data.
#' @param output_dir Path to the output folder.
#' @param sample_data_path Path to the sample data which should contatin the sample_id_column and sample_folder_column
#' @param sample_folder_column The name of the column that has sample folder names
#' @param sample_id_column The name of the column that has sample ids
#' @param thread_num Integer number of threads to run mclapply statements
#'
#' @return A path to the rds file.
#'
#' @import magrittr data.table housekeeping binfotron plyr stringr utils parallel
#'
#' @export

post_process_hla_profiler = function(
  input_file_paths,# = system(paste0("ls ", RAW_DATA_DIR, "hla_profiler/sample_output/*/*.HLATypes.txt"), intern = TRUE)
  output_dir,# = file.path(base_dir, "post_processing", "hla_profiler")
  sample_data_path,# = file.path(base_dir, "sample_data", "sample_data.tsv")
  sample_folder_column = "Sample_Folder",
  sample_id_column = "Sample_ID",
  thread_num = 16
){

  readme_path = file.path(output_dir, "readme.txt")
  a = function(...){
    my_output = paste0(...)
    if(!is.null(readme_path)){
      write(my_output, readme_path, append = TRUE)
    }
    message(my_output)
  }

  a(paste0("Parsing HLA type data: ", this_script_path) %>% as.header1)
  a(paste0("Reading in files") %>% as.header1)
  a("")

  # a("Reading in files from input_file_paths:")
  #   read_data = mclapply(input_file_paths, function(input_file_path){
  #     # a("  ", input_file_path)
  #     message(input_file_path)
  #     # res_df = fread(input_file_path, select = c("Allele1_Accession", "Allele2_Accession", "Allele1", "Allele2", "Allele1 Comments"), data.table = F)
  # #    return_list = lapply(counts_df[["NumReads"]], function(x)x) # rbindlist needs a list so we turn this into a list
  #  #   names(return_list) = counts_df[["Name"]] # Name the list items so they get assigned to the right column
  #     # return(res_df)
  #     print(res_df)
  #   }, mc.cores = thread_num)
  #   a("")

  HLA_data = do.call(plyr::rbind.fill, mclapply(input_file_paths, function(input_file_path){
    # a("  ", input_file_path)
    res_file = gsub(".HLATypes.txt", "", sapply(stringr::str_split(input_file_path, "/"), tail, 1))

    res_df = data.table::fread(input_file_path, select = c("Allele1_Accession", "Allele2_Accession", "Allele1", "Allele2", "Allele1 Comments"), data.table = F)
    res_df = res_df[!(res_df$`Allele1 Comments` == "Not enough reads to make call"),]
    res_df$`Allele1 Comments` = NULL

    res_df$Allele_Type = gsub("[*].*$", "", res_df$Allele1)
    HLA_list = res_df$Allele_Type
    Class_1_HLA_type = c("A", "B", "C")
    Class_1_HLA = HLA_list[HLA_list %in% Class_1_HLA_type]

    Other_HLA = HLA_list[!(HLA_list %in% Class_1_HLA_type)]

    res_df$new_col_1 = sub("(:[^:]+):.*", "\\1", res_df$Allele1)
    res_df$new_col_1 = sub("[*]", "_", res_df$new_col_1)
    res_df$new_col_1 = sub("[:]", "_", res_df$new_col_1)
    res_df$new_col_2 = sub("(:[^:]+):.*", "\\1", res_df$Allele2)
    res_df$new_col_2 = sub("[*]", "_", res_df$new_col_2)
    res_df$new_col_2 = sub("[:]", "_", res_df$new_col_2)

    Allele_list = unique(c(res_df$new_col_1, res_df$new_col_2))

    column_names = c("Sample_ID", "Class_1_HLA", "Other_HLA", Allele_list)

    dat <- data.frame(matrix(ncol = length(column_names), nrow = 0))
    colnames(dat) <- column_names
    dat[nrow(dat) + 1,] = c(res_file, paste( unlist(Class_1_HLA), collapse=','), paste( unlist(Other_HLA), collapse=','), rep("T", length(colnames(dat)) - 3))
    return(dat)
  },  mc.cores = thread_num))

  HLA_data[is.na(HLA_data)] = "F"
  HLA_data = HLA_data[, order(names(HLA_data))]
  HLA_data = HLA_data[, housekeeping::move_to_front(names(HLA_data), c("Sample_ID", "Class_1_HLA", "Other_HLA"))]

  # return(HLA_data)

 file_output_path = paste0(output_dir, "/HLATypes.tsv")
  fwrite(HLA_data, file_output_path, sep = "\t")
}
