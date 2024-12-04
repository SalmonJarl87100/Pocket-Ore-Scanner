-- ask user if program should overwrite existing folder
if fs.exists("/ArScanner/") then
    local response = ""
    while response ~= "n" and response ~= "y" do
        io.write('\nFolder "ArScanner" already exists. Overwrite?(y/n):')
        response = io.read()
    end

    if response == "n" then
        print("Stopping installation.")
        return

    else
        fs.delete("/ArScanner")
    end
end

-- ask user if program should overwrite existing shortcut file
if fs.exists("/arScanner.lua") then
    local response = ""
    while response ~= "n" and response ~= "y" do
        io.write('\nShortcut file "arScanner.lua" already exists. Overwrite?(y/n):')
        response = io.read()
    end

    if response == "n" then
        print("Stopping installation.")
        return

	else
		fs.delete("/arScanner.lua")
    end
end

-- make program folder
fs.makeDir("/ArScanner")

-- download main file
shell.run("wget https://raw.githubusercontent.com/SalmonJarl87100/Pocket-Ore-Scanner/refs/heads/main/main.lua /ArScanner/main.lua")

-- download basalt file
shell.run("wget https://raw.githubusercontent.com/SalmonJarl87100/Pocket-Ore-Scanner/refs/heads/main/basalt.lua /ArScanner/basalt.lua")

-- download scanner program
shell.run("wget https://raw.githubusercontent.com/SalmonJarl87100/Pocket-Ore-Scanner/refs/heads/main/scanner.lua /ArScanner/scanner.lua")

-- download shortcut file
shell.run("wget https://raw.githubusercontent.com/SalmonJarl87100/Pocket-Ore-Scanner/refs/heads/main/arScanner.lua /arScanner.lua")

-- dowload pine3d
shell.run("pastebin run qpJYiYs2")
shell.run("copy Pine3D.lua ArScanner/")
shell.run("copy betterblittle.lua ArScanner/")
shell.run("delete Pine3D.lua betterblittle.lua Mountains.lua noise.lua")

print("Installation complete. Thank you for choosing my program.")
