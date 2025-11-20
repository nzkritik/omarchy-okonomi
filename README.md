# Omarchy-Okonomi

### Purpose:
The purpose of this repo is to add some setup choice on tyop of Omarchy to fit your needs. Your choices should be applied to a freash, upgraded base install of Omarchy.  

Omarchy is based on the concept of "Opinionated Arch Linux", taking inspiration from the japanese word Omakase.  
Omakase (お任せ), meaning "I'll leave it up to you" or "Chef's choice".  
This repo flips that and starts with Omarchy, then adds some choice into the mix.  

i.e. Okonomi (お好み) meaning "as you like" or "Customers choice".  

Therefore this is Omarchy-Okonomi. ("customers choice" not "chefs choice")  

---  

### Key Justifications:
* I'm not a developer, so some of Omarchy's default applications I don't use day to day
* I like the idea of installing a setup Arch system, but want my defaults applied post-install
  * Removing Apps i don't use
  * Adding apps I do use
  * Tweaking some keybindings
  * Tweaking some configs

### Instructions:
* Install omarchy
* Do a system update (using the built-in update omarchy)
* Clone this repo  
```git clone https://github.com/nzkritik/omarchy-supplement.git```   
```cd omarchy-supplement```   
* (Optional) Review the files and make changes to suit your needs
* Run the install script   
```./install-all.sh```  
* Reboot your system and enjoy

### ToDo list:
- [ ] configure install script to provide more flexible options for installs  
  - [X] organise the install scripts into categories and shift them to a sub-folder  
    - [X] Web Browsers  
    - [X] Creativity Apps  
    - [ ] Torrent Apps  
    - [ ] Development Apps  
    - [ ] File Management Apps  
    - [ ] System Tools/Utilities  
    - [ ] System Tweaks  
  - [X] provide options to install only certain categories of apps/configs  
- [ ] Structure the install flow to allow for minimal changes or very  tweaked installs
- [ ] Add more custom apps/configs as I find them  
- [ ] Do better testing to ensure installation doesn't break  

### References:

* The great work DHH and the team have done on [Omarchy](https://omarchy.org) (repo here: [github](https://github.com/basecamp/omarchy))
* This config is based on [typecraft's](https://typecraft.dev/) own custonisations (repo here:[github](https://github.com/typecraft-dev/omarchy-supplement))

---  

### Disclaimer:
This is a work in progress, that I'm working on gradually while learning git and other linux tools.  

---  