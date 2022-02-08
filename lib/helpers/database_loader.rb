module DatabaseLoader
  def load_from_file(file)
    YAML.load_file(file) if File.exist?(file)
  end

  def store_to_file(data, file, dir)
    Dir.mkdir(dir) unless Dir.exist?(dir)
    File.write(file, data.to_yaml)
  end
end
