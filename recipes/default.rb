# xfsdump is not an Amazon Linux package at this moment.
case node[:platform]
when 'debian','ubuntu'
  package 'xfsdump'
  package 'xfslibs-dev'
when 'redhat','centos','fedora','amazon'
  package 'xfsprogs-devel'
end

include_recipe 'aws'

# VirtIO device name mapping
if BlockDevice.on_kvm?

  cookbook_file "/usr/local/bin/virtio-to-scsi" do
    source "virtio-to-scsi"
    owner "root"
    mode 0755
  end

  cookbook_file "/etc/udev/rules.d/65-virtio-to-scsi.rules" do
    source "65-virtio-to-scsi.rules"
    owner "root"
    mode 0644
  end
  
  execute "Reload udev rules" do
    command "udevadm control --reload-rules"
  end

  execute "Let udev reprocess devices" do
    command "udevadm trigger"
  end

end

groups = node[:ebs][:groups]
unless groups.nil? 
  groups.each do | groupId|
    unless node[:ebs][groupId].nil? || node[:ebs][groupId].empty? 
      Chef::Log.info "Attaching EBS(s) from group #{groupId}"
      group = node[:ebs][groupId]
      node.force_override[:ebs][:raids] = node[:ebs][:raids].merge(group[:raids]) unless group[:raids].nil?
      node.force_override[:ebs][:volumes] = node[:ebs][:volumes].merge(group[:volumes]) unless group[:volumes].nil?
    end
  end
end

include_recipe "ebs::volumes" unless node[:ebs][:volumes].empty?
include_recipe "ebs::raids" unless node[:ebs][:raids].empty?
