# encoding: utf-8

# This module is used to take a file or directory, perform an operation on
# the file(s), write the output to the corresponding text file(s), and
# optionally archive the file(s).
#
# Main functions:
#
#   process_file(input_source, operation, options = { ... })
#   process_dir(input_source, operation, options = { ... })
#
# Example usage:
#
#   FileProcessor.process_file('/home/user/sample.pdf',
#                           method(:get_text),
#                           {output_dest: '/home/user/output',
#                             archive_dest: '/home/user/archive'})
#   FileProcessor.process_dir('/home/user/myPDFs/')
#                          method(:get_text),
#                          {output_dest: '/home/user/output',
#                            output_dir_dup: true,
#                            archive_dest: '/home/user/archive',
#                            archive_dir_dup: true})
#
# Options:
#
#          log_file  -  If specified, this is the location where a log file
#                       will be placed, tracking the process.
#
#        ouput_dest  -  If specified, this is the directory where the resulting
#                       ouput file(s) will be placed. If not specified, the
#                       resulting output files will be placed in the same path
#                       as the file(s)
#
#    output_dir_dup  -  If set to true, and output_dest is specified and
#                       process_dir is called, any subfolder structure in the
#                       input_source directory will be duplicated in the
#                       output_dest.
#
#      archive_dest  -  If specified, this is the directory where the file(s)
#                       will be moved to if they are successfully processed.
#
#   archive_dir_dup  -  If set to true, and archive_dest is specified and
#                       process_dir is called, any subfolder structure in the
#                       input_source directory will be duplicated in the
#                       archive_dest.

module FileProcessor
  require 'fileutils'
  require 'find'
  require 'logger'

  attr_accessor :log

  module_function
  def process_file(file, operation, options = {})
    validate_file_inputs(file, operation, options)
    do_work(file, operation, options)
  end

  def process_dir(dir, operation, options = {})
    validate_dir_inputs(dir, operation, options)
    files = files_in_dir(dir)
    successes, failures = 0, 0
    files.each do |file|
      begin
        do_work(file, operation, options, dir) == 'Success' ? successes += 1 : failures += 1
      rescue StandardError => e
        @log.nil? ? (puts e.message) : @log.error("Error processing #{file}: #{e}")
        failures += 1
      end
    end
    "Successfully performed the operation on #{successes} files. (#{failures} failures)"
  end

  def do_work(file, operation, options, dir = '/')
    operation_output = operation.call(file)
    'Operation failed' if operation_output.nil? || operation_output.empty?
    output_textfile = output_file(file, options, dir)
    File.open(output_textfile, 'w') { |f| f.write(operation_output) }
    archive_file(file, options, dir) unless options[:archive_dest].nil?
    'Success'
  end

  def validate_file_inputs(file, operation, options)
    fail 'Cannot duplicate directory for a file.' if options[:output_dir_dup] == true || options[:archive_dir_dup] == true
    validate_general_options(file, operation, options)
    fail "Argument is not file: #{file}" unless File.file?(file)
  end

  def validate_dir_inputs(dir, operation, options)
    fail "Argument is not a directory: #{dir}" unless File.directory?(dir)
    validate_general_options(dir, operation, options)
    fail 'Cannot specify output_dir_dup without specifying output_dest.' if options[:output_dest].nil? && options[:output_dir_dup] == true
    fail 'Cannot specify archive_dir_dup without specifying archive_dest.' if options[:archive_dest].nil? && options[:archive_dir_dup] == true
  end

  def validate_general_options(input_source, operation, options)
    fail 'You must specify a filename or directory.' if input_source.nil?
    fail "Could not locate input source: #{input_source}." unless File.exists?(input_source)
    fail 'Operation argument must be a Proc or a Method.' unless operation.is_a?(Proc) || operation.is_a?(Method)
    fail "Could not locate output_dest: #{options[:output_dest]}." unless options[:output_dest].nil? || File.exists?(options[:output_dest])
    fail "Could not locate archive_dest: #{options[:archive_dest]}." unless options[:archive_dest].nil? || File.exists?(options[:archive_dest])
    @log = Logger.new(options[:log_file]) unless options[:log_file].nil?
  end

  def archive_file(file, options, dir = '/')
    archive_path = archive_file_path(file, options, dir)
    FileUtils.mkdir_p(archive_path)
    FileUtils.mv(file, archive_path)
  end

  def output_file(file, options = {}, dir = '/')
    file_name = File.basename(file, File.extname(file)) + '.txt'
    file_path = output_file_path(file, options, dir)
    FileUtils.mkdir_p(file_path)
    file_path + '/' + file_name
  end

  def archive_file_path(file, options, dir)
    options[:archive_dir_dup] == true ? options[:archive_dest] + file_subpath(file, dir) : options[:archive_dest]
  end

  def output_file_path(file, options = {}, dir)
    return File.dirname(file) if options[:output_dest].nil?
    options[:output_dir_dup] == true ? options[:output_dest] + file_subpath(file, dir) : options[:output_dest]
  end

  def file_subpath(file, dir)
    return '/' if dir == '/'
    origin_base = File.basename(dir)
    File.dirname(file).split(origin_base)[1] || '/'
  end

  def files_in_dir(dir)
    files = []
    Find.find(dir).each { |path| files << path if File.file?(path) }
    files
  end
end
