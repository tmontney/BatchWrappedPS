# Overview
This demonstrates embedding a PowerShell script inside a batch script. This allows for double-click-to-run of PowerShell scripts. Additionally, it is a proof-of-concept for embedding of scripts and use of `EncodedArguments` parameter.

# History
I believe this originated with the deployment of a Lenovo utility that only came as a binary. I needed to do more than just call the utility, so direct deployment wasn't an option. I could download the utility after deployment, but it bugged me I couldn't integrate it into the script. (This involved complicated use of variables across multiple lines, use of [certutil](https://learn.microsoft.com/en-us/windows-server/administration/windows-commands/certutil), and writing to the disk.) From there, I got the idea to convert the binary to base64 and put it in the script. After that, I wondered if I could embed a PS script in a batch script.

In the original commit, you'll notice it's more complicated than it needed to be. At the time, for whatever reason, I didn't remember PowerShell could accept an encoded form of the script. I reviewed it, when someone mentioned converting PS scripts to binary, and simplified it.

# EncodedArguments
Of course, I could embed "arguments" in the script, but that's not really the same thing as using them properly. I discovered the EncodedArguments parameter, but couldn't get it working. Additionally, there seemed to be no reference aside from [this doc](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_powershell_exe?view=powershell-5.1#-encodedarguments-base64encodedarguments) that it exists (and the error output from PowerShell itself) on its usage. Refer to [this commit](https://github.com/tmontney/BatchWrappedPS/commit/7c1d0b17773dc9478365bc18566bdbda1b816013) and my comment for the solution.
