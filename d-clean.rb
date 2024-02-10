require 'digest'
require 'fileutils'

def hash_file(filename)
  Digest::SHA256.file(filename).hexdigest
end

def find_files_by_size(folder)
  size_to_files = {}
  total_files = 0
  cumulative_files_per_size = Hash.new(0)

  Dir.glob("#{folder}/**/*").each do |file|
    next unless File.file?(file)

    size = File.size(file)
    size_to_files[size] ||= []
    size_to_files[size] << file
    total_files += 1

    if size_to_files[size].length > 1
      cumulative_files_per_size[size] = size_to_files[size].length
    end

    cumulative_files_count = cumulative_files_per_size.values.sum
    puts "1차 작업중: 확인한 파일 수 (#{cumulative_files_count}/#{total_files}) #{size} : #{size_to_files[size].length} - #{file}"
  end

  size_to_files
end

def find_duplicate_files(files_by_size)
  duplicates = {}
  group_count = 0

  files_by_size.each do |size, files|
    next if files.length < 2  # 중복이 없는 파일 그룹은 제외
    group_count += 1  # 중복이 있는 그룹의 수를 카운트

    hashes = {}
    files.each do |file|
      hash = hash_file(file)
      if hashes[hash]
        duplicates[hashes[hash]] ||= []
        duplicates[hashes[hash]] << file
      else
        hashes[hash] = file
      end
    end
  end

  [duplicates, group_count]
end

def move_duplicates(duplicates, target_folder, log_file)
  FileUtils.mkdir_p(target_folder) unless Dir.exist?(target_folder)
  File.open(log_file, 'w') do |log|
    duplicates.each do |original, dup_files|
      hash = hash_file(original)
      log.puts("#{hash} - #{original}")
      dup_files.each do |file|
        new_location = File.join(target_folder, File.basename(file))
        FileUtils.mv(file, new_location)
        log.puts("  #{file}")
      end
      log.puts("\n")
    end
  end
end

source_folder = "."
target_folder = "./duplicates"
log_file = "#{source_folder}/log.txt"

files_by_size = find_files_by_size(source_folder)
duplicates, group_count = find_duplicate_files(files_by_size)
move_duplicates(duplicates, target_folder, log_file)

duplicates.each_with_index do |(_, dup_files), index|
  puts "2차 작업중: 같은 용량 파일 그룹 #{index + 1}/#{group_count}"
end
