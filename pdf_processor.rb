require 'pdf-reader'
require 'fileutils'
require 'find'
require 'logger'
require 'yaml'

CONFIG_FILE = 'config.yml'
@config = nil
@logger = nil

#TODO: Turn this into a module
def main
  #TODO: allow users to pass in arguments for specified config file, or file to process, etc
  set_config
  pdfs = gather_pdfs_from_base_directory
  successfully_written_pdfs = write_pdfs_to_text_files(pdfs)
  archive_select_files_from_dir(successfully_written_pdfs,
                                @config['process_queue_base_directory'],
                                @config['archive_base_directory'])
end

def archive_select_files_from_dir(files, dir, archive)
  files.each do |file|
    archive_path = archive + get_file_subpath(dir, file)
    FileUtils.mkdir_p(archive_path)
    FileUtils.mv(file,archive_path)
  end
end

def write_pdfs_to_text_files(pdfs)
  written_pdfs = []
  pdfs.each do |pdf|
    begin
      write_pdf_text(pdf)
      written_pdfs << pdf
    rescue StandardError => e
      @logger.error("Can't process #{pdf}")
      @logger.error(e)
    end
  end
  written_pdfs
end

def write_pdf_text(pdf)
  text_file = get_text_file(pdf)
  pdf_reader = PDF::Reader.new(pdf)
  write_document_info(text_file, pdf_reader)
  pdf_reader.pages.each { |page| text_file.write(page.text) unless page.text.strip.empty? }
  text_file.close
end

def write_document_info(text_file, pdf_reader)
  text_file.write("PDF_VERSION: #{pdf_reader.pdf_version}\n")
  text_file.write("PDF_INFO: #{pdf_reader.info}\n")
  text_file.write("PDF_METADATA: #{pdf_reader.metadata}\n")
  text_file.write("PDF_PAGE_COUNT: #{pdf_reader.page_count}\n")
end

def get_text_file(pdf)
  text_file_path = @config['text_results_base_directory'] + get_file_subpath(@config['process_queue_base_directory'], pdf) + '/'
  FileUtils.mkdir_p(text_file_path)
  text_file = text_file_path + File.basename(pdf).split('.')[0] + '.txt'
  File.open(text_file, 'w')
end

def get_file_subpath(origin_path, file_path)
  origin_base = origin_path.split('/').last
  if origin_base.empty? then fail "Cannot get subpath from: #{origin_path}" end
  file_sub_path = file_path.split(origin_base)[1]
  File.dirname(file_sub_path)
end

def duplicate_subdirectory_structure(origin_dir, dest_dir)
  origin_base = origin_dir.split('/').last
  if original_base.empty? then fail "Cannot duplicate directory: #{original}" end
  Find.find(original) do |path|
    if File.directory?(path)
      subdir = path.split(original_base)[1]
      subdir.nil? ?  FileUtils.mkdir_p(copy + '/') : FileUtils.mkdir_p(copy + subdir)
    end
  end
end

def gather_pdfs_from_base_directory
  pdfs = []
  Find.find(@config['process_queue_base_directory']) do |path|
    pdfs << path if path.match(/.*\.pdf$/)
  end
  pdfs
end

def set_config
  if !(File.exists?(File.join(__dir__, CONFIG_FILE)))
    fail "Config file '#{File.join(__dir__, CONFIG_FILE)}' does not exist!"
  end
  @config = YAML::load_file(File.join(__dir__, CONFIG_FILE))
  @logger = Logger.new(@config['log_file'])
  @logger.level = Logger::INFO
end

main
