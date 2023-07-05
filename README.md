# Super-Glue
Set of scripts to 'glue' Jamf Pro, [Super](https://github.com/Macjutsu/super) and optionally a macOS LAPS solution together

[Super](https://github.com/Macjutsu/super) is a script that helps automate informing users of the availability of macOS updates _and_ upgrades. It can further help automate providing Admin level credentials to automate such installations. This is sadly something Apple are making harder and harder for Mac admins managing a fleet of Macs. Apple's (incorrect) assumption is that all users own their computers, all users are themselves admins and all users not only know what to do but can be relied on to do it.

The original [Super](https://github.com/Macjutsu/super) script greatly helps automate things but assumes all the Macs have the same local admin credentials. These days it is considered good practice to either not have a local admin account - which is not always feasible or that at least each one has a unique random password. It is common therefore to store the random password in an MDM system although originally this is based on an approach used first for Windows machines where the password is stored in Active Directory.

This script therefore sits between Jamf Pro and the 'real' Super script so that it handles retrieving the randomised LAPS i.e. local admin password and then passes this along with other parameters to the real Super script.

This script can either pass a fixed identical password to the Super script, or retrieve an unencrypted password from an extension attribute allowing unique passwords per computer, or it can also retrieve both a decryption key and an encrypted random password, decrypt the encrypted value and then pass this to the real Super script.

This script therefore acts as the 'glue' to join Jamf Pro, Super and a macOSLAPS solution together.

I am myself intending to use this with the following LAPS solution [macOSLAPS](https://github.com/PezzaD84/macOSLAPS)

The main component is a script which Jamf Pro calls, this Super-Glue script receives the command paramters that would otherwise be sent to the real Super script. It then as needed substitutes and/or retrieves the local admin password in to the command paramters and passes them to the real Super script. A second script is also provided which will if needed pre-populate the two extension attributes with initial values. This is because in the case of macOSLAPS it assumes it would create the local admin account but in my case and I suspect many others, the local admin account has already been created - possibly via Jamf Pro, or Jamf Connect. This second script will therefore set initial standard values to the extension attributes which macOSLAPS will then be able to use to set new random values to.

Note: If and when macOSLAPS changes the local admin password not only in the extension attributes but also of the local admin accounts itself, then it will be necessary to re-run the Super-Glue script so it can then tell the real Super script the new credentials. This can be automatically triggered by adding a 'Files and Processes' entry to the macOSLAPS Jamf policy so that it executes the command ```jamf policy -event super-glue``` which will triger re-running the super-glue script. The super-glue script will then read the updated extension attributes containing the updates LAPS credentials and pass them to the 'real' super script.
![Screenshot 2023-07-05 at 13 57 35](https://github.com/jelockwood/Super-Glue/assets/4300786/4227d9dd-b115-493a-817a-e17913fe2578)


