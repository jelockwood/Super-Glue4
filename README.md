# Super-Glue
Set of scripts to 'glue' Jamf Pro, [Super](https://github.com/Macjutsu/super) and optionally a macOS LAPS solution together

[Super](https://github.com/Macjutsu/super)https://github.com/Macjutsu/super is a script that helps automate informing users of the availability of macOS updates _and_ upgrades. It can further help automate providing Admin level credentials to automate such installations. This is sadly something Apple are making harder and harder for Mac admins managing a fleet of Macs. Apple's (incorrect) assumption is that all users own their computers, all users are themselves admins and all users not only know what to do but can be relied on to do it.

The original [Super](https://github.com/Macjutsu/super)https://github.com/Macjutsu/super script greatly helps automate things but assumes all the Macs have the same local admin credentials. These days it is considered good practice to either not have a local admin account - which is not always feasible or that at least each one has a unique random password. It is common therefore to store the random password in an MDM system although originally this is based on an approach used first for Windows machines where the password is stored in Active Directory.

This script therefore sits between Jamf Pro and the 'real' Super script so that it handles retrieving the randomised LAPS i.e. local admin password and then passes this along with other parameters to the real Super script.

This script can either pass a fixed identical password to the Super script, or retrieve an unencrypted password from an extension attribute allowing unique passwords per computer, or it can also retrieve both a decryption key and an encrypted random password, decrypt the encrypted value and then pass this to the real Super script.
