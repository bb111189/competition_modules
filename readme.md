About
=============
Borne out of the authors experiences at the CCDC and similar compeititions, a need for enhanced persistance and fun modules was recognized. This project provides metasploit modules which are useful at such competitions. Mainly for the red team :)


Metrepreter Scripts
============
* NoSafe - Disables safe mode by patching the NTLDR, works on XP and 2k3 boxes only
* RegRun - Autorun files using a registry key
* RickRoll - Rick Roll the victim
* Wallpaper - Change the victim wallpaper
* Schtask - Schedule a task on the victim system

Usage
=============
To utilize these modules, simply pull them down and load them in the framework: 

msf> loadpath /path/to/competition_modules
[+] xx modules loaded.
