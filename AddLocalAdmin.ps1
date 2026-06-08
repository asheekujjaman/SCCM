# Define the username and password
$UserName = "ashik"
$Password = "nil.1564" | ConvertTo-SecureString -AsPlainText -Force

# Create the local user
New-LocalUser -Name $UserName -Password $Password -FullName "Local Administrator" -Description "SCCM deployed local admin account"

# Add the user to Administrators group
Add-LocalGroupMember -Group "Administrators" -Member $UserName

