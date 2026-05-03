#!/usr/bin/env ruby
require 'xcodeproj'

PROJECT = '/Users/joshuacardozo/Developer/Durigo-ios-and-mac/Durigo.xcodeproj'
TARGET = 'Durigo'
GROUP_NAME = 'POS'
FILES = %w[
  POSModels.swift
  POSStore.swift
  POSContainer.swift
  TablesGridView.swift
  TakeOrderView.swift
  OrderDetailView.swift
  TableMergeView.swift
  ReservationDialogView.swift
]

project = Xcodeproj::Project.open(PROJECT)
target = project.targets.find { |t| t.name == TARGET }
raise "Target #{TARGET} not found" unless target

durigo_group = project.main_group['Durigo']
raise "Durigo group not found" unless durigo_group

# Avoid duplicates if rerun.
pos_group = durigo_group[GROUP_NAME] || durigo_group.new_group(GROUP_NAME, 'POS')

FILES.each do |fname|
  existing = pos_group.files.find { |f| f.path == fname }
  next if existing && target.source_build_phase.files_references.include?(existing)

  ref = existing || pos_group.new_reference(fname)
  unless target.source_build_phase.files_references.include?(ref)
    target.add_file_references([ref])
  end
  puts "Added #{fname}"
end

project.save
puts "Saved #{PROJECT}"
