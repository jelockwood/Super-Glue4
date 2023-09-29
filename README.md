# Super-Glue4
Script to 'glue' Jamf Pro, [Super](https://github.com/Macjutsu/super) and optionally a macOS LAPS solution together

Note: This is a new version of my Super-Glue script specifically for use the new version 4 of Kevin M. White's SUPER script. Using my version 3 script with his version 4 script or vice versa will result in errors.

[Super](https://github.com/Macjutsu/super) is a script that helps automate informing users of the availability of macOS updates _and_ upgrades. It can further help automate providing Admin level credentials to automate such installations. This is sadly something Apple are making harder and harder for Mac admins managing a fleet of Macs. Apple's (incorrect) assumption is that all users own their computers, all users are themselves admins and all users not only know what to do _and can be relied on to do it_.

_Thanks go to the author of Super - Kevin M. White, as you should be able to tell if you look at the code in my script it is deliberately based on his script as it is mainly doing the same identical processing of command parameters. I have removed large sections of his script which in my case are not needed but equally likely a large amount of code remains which is not strictly necessary for the limited work my script does and likely is never going to be called in my script._

The original [Super](https://github.com/Macjutsu/super) script greatly helps automate things but assumes all the Macs have the same local admin credentials. These days it is considered good practice to either not have a local admin account - which is not always feasible or that at least each one has a unique random password. It is common therefore to store the random password in an MDM system although originally this is based on an approach used first for Windows machines where the password is stored in Active Directory.

This script therefore sits between Jamf Pro and the 'real' Super script so that it handles retrieving the randomised LAPS i.e. local admin password and then passes this along with other parameters to the real Super script.

This script can either pass a fixed identical password to the Super script, or retrieve an unencrypted password from an extension attribute allowing unique passwords per computer, or it can also retrieve both a decryption key and an encrypted random password, decrypt the encrypted value and then pass this to the real Super script.

This script therefore acts as the 'glue' to join Jamf Pro, Super and a macOSLAPS solution together.

I am myself using this with the following LAPS solution [macOSLAPS](https://github.com/PezzaD84/macOSLAPS)

The main component is a script which Jamf Pro calls, this Super-Glue script receives the command paramters that would otherwise be sent to the real Super script. It then as needed substitutes and/or retrieves the local admin password in to the command paramters and passes them to the real Super script. A second script is also provided which will if needed pre-populate the two extension attributes with initial values. This is because in the case of macOSLAPS it assumes it would create the local admin account but in my case and I suspect many others, the local admin account has already been created - possibly via Jamf Pro, or Jamf Connect. This second script will therefore set initial standard values to the extension attributes which macOSLAPS will then be able to use to set new random values to.

Since Super-Glue not only reads any updated LAPS credentials to pass to the 'real' Super script but also installs or reinstalls Super it is not necessary to define any Super specific Policy in Jamf Pro. You _do_ still need to define the same Profile in Jamf Pro as this will still be read by the Super script after it is installed (or re-installed) by Super-Glue. Super-Glue does require its own policy and will also require the same script command parameters to be passed to Super-Glue which it will then pass to the 'real' Super script. Super-Glue also uses two optional parameters and adds extra capability to one existing parameter.

<img width="818" alt="Screenshot 2023-07-11 at 09 52 55" src="https://github.com/jelockwood/Super-Glue/assets/4300786/06e2b3fd-73fc-4b89-af98-06e6dbbd4cd1">

Note: If and when macOSLAPS changes the local admin password not only in the extension attributes but also of the local admin accounts itself, then it will be necessary to re-run the Super-Glue script so it can then tell the real Super script the new credentials. This can be automatically triggered by adding a 'Files and Processes' entry to the macOSLAPS Jamf policy so that it executes the command ```jamf policy -event super-glue``` which will triger re-running the super-glue script. The super-glue script will then read the updated extension attributes containing the updates LAPS credentials and pass them to the 'real' super script.
![Screenshot 2023-07-05 at 13 57 35](https://github.com/jelockwood/Super-Glue/assets/4300786/4227d9dd-b115-493a-817a-e17913fe2578)

Since we need to regularly re-run the super-glue script and hence rerun the super install process we should _not_ include as a paramter the super reset option. This allows updating the existing super setup each time macOSLAPS does a LAPS update.

**Notes:**
1. It is critical that the LAPS password rotation interval be significantly longer than the SUPER update/upgrade recheck cycle. I therefore have SUPER set to recheck for new Apple updates/upgrades each day and LAPS set to rotate the LAPS password once a week. This is because in order to get SUPER to reload the updated LAPS password I reinstall SUPER and this resets the recheck counter. If the timescale for LAPS was the same or shorter than the SUPER interval then SUPER would be being reset so often it would never get a chance to run.
2. Related to the above, the SUPER reinstall process resets the launchdaemon and the counter defined in it, it would also unload the launchdaemon, my script therefore deliberately unloads the launchdaemon (which may not be strictly necessary) but does also deliberately load the launchdaemon after the (re)installation is complete which does seem to be necessary.
