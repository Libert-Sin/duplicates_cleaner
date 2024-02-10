require 'digest'
require 'fileutils'

def hash_file(filename)
  # 파일의 내용을 읽어 해시값을 계산합니다.
  Digest::SHA256.file(filename).hexdigest
end

def find_duplicate_files(folder)
  hashes = {}
  duplicates = {}
  file_count = 0

  Dir.glob("#{folder}/**/*").each do |file|
    next unless File.file?(file)

    file_count += 1
    puts "Processing file #{file_count}: #{file}"  # 진행 상황 출력

    hash = hash_file(file)

    if hashes[hash]
      # 중복 파일이면 duplicates에 추가합니다.
      duplicates[hashes[hash]] ||= []
      duplicates[hashes[hash]] << file
    else
      # 해시값을 해시 테이블에 저장합니다.
      hashes[hash] = file
    end
  end

  duplicates
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

duplicates = find_duplicate_files(source_folder)
move_duplicates(duplicates, target_folder, log_file)
