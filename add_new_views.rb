require 'xcodeproj'
project_path = '火柴游戏.xcodeproj'
project = Xcodeproj::Project.open(project_path)
target = project.targets.first

group = project.main_group.find_subpath(File.join('火柴游戏', 'Games'), true)

# Add XiehouyuDictionaryView.swift
unless group.files.any? { |f| f.path == 'XiehouyuDictionaryView.swift' }
  file_ref = group.new_file('XiehouyuDictionaryView.swift')
  target.source_build_phase.add_file_reference(file_ref)
end

# Add SanzijingView.swift
unless group.files.any? { |f| f.path == 'SanzijingView.swift' }
  file_ref2 = group.new_file('SanzijingView.swift')
  target.source_build_phase.add_file_reference(file_ref2)
end

project.save
