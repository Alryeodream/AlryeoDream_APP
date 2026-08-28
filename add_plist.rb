require 'xcodeproj'
project_path = 'ios/Runner.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Find Runner group
runner_group = project.main_group.find_subpath('Runner', true)

# Check if file is already added
file_ref = runner_group.files.find { |file| file.path == 'GoogleService-Info.plist' }

if file_ref.nil?
  puts 'Adding GoogleService-Info.plist to project...'
  file_ref = runner_group.new_reference('GoogleService-Info.plist')
  
  # Add to main target
  target = project.targets.find { |t| t.name == 'Runner' }
  target.add_resources([file_ref])
  
  project.save
  puts 'Saved!'
else
  puts 'File already exists in project.'
end
