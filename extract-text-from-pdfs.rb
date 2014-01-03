require 'fileutils'
require './lib/pdf-text-extractor'

ARCHIVE_DIR = 'archive'
RESULTS_DIR = 'text_results'
LOGS_DIR = 'logs'
LOG_FILE = LOGS_DIR + '/extract-text-from-pdfs.log'

def main

  fail 'You must specify a pdf or a directory to process.' if ARGV.size < 1

  ARGV.each do |arg|

    if File.file?(arg)
      FileUtils.mkdir_p(RESULTS_DIR)
      FileUtils.mkdir_p(ARCHIVE_DIR)
      FileUtils.mkdir_p(LOGS_DIR)
      puts PDFToTextFile.process_pdf(arg, {output_dest: RESULTS_DIR,
                                            archive_dest: ARCHIVE_DIR ,
                                            log_file: LOG_FILE})
    elsif File.directory?(arg)
      FileUtils.mkdir_p(RESULTS_DIR)
      FileUtils.mkdir_p(ARCHIVE_DIR)
      FileUtils.mkdir_p(LOGS_DIR)
      puts PDFToTextFile.process_dir(arg, {output_dest: RESULTS_DIR,
                                           output_dir_dup: true,
                                           archive_dest: ARCHIVE_DIR ,
                                           archive_dir_dup: true,
                                           log_file: LOG_FILE})
    else
      fail "Invalid argument: #{arg}"
    end
  end

end

main
