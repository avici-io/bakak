task default: %w[test]

task :run do
  load 'env.rb'
  system 'ruby index.rb'
end

task :test do
  load 'env.rb'
  system 'rspec'
end

task :docs do
  `apidoc -i . -o apidoc/`
end