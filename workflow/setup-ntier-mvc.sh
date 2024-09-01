#!/bin/bash
# Description: This script will create a new N-Tier MVC project. (Models, DAL, BLL, MVC)
# Author: JJ

read -p "Enter the name of the project: " name
read -p "Enter the path to the project: " path
read -p "Enter the name of the database: " database
read -p "Do you want to add authentication? (y/n): " withAuth

if [ -z "$path" ]; then
    path="./"
else
    if [ ! -d "$path" ]; then
        echo "Path does not exist."
        exit 1
    fi
fi

if [ -z "$name" ] || [ -d "$name" ]; then
    echo "Project name is empty, or project already exists."
    exit 1
fi

if [ -z "$database" ]; then
    databas=$name
fi

if [ -z "$withAuth" ]; then
    withAuth="y"
fi

# Create project directory
cd $path
mkdir $name
cd $name
dotnet new sln

# Models
dotnet new classlib -n $name.Models
cd $name.Models
dotnet add package Microsoft.EntityFrameworkCore
rm Class1.cs
cd ..

# DAL
dotnet new classlib -n $name.DAL
cd $name.DAL
dotnet add package Microsoft.EntityFrameworkCore
dotnet add package Microsoft.EntityFrameworkCore.SqlServer
dotnet add package Microsoft.EntityFrameworkCore.Design
dotnet add package Microsoft.EntityFrameworkCore.Tools
if [ $withAuth == "y" ]; then
    dotnet add package Microsoft.AspNetCore.Identity.EntityFrameworkCore
fi
dotnet add reference ../$name.Models/$name.Models.csproj
rm Class1.cs
echo "using Microsoft.EntityFrameworkCore;
using $name.Models;
namespace $name.DAL
{
    public class ${name}DbContext : DbContext
    {
        public ${name}DbContext(DbContextOptions<${name}DbContext> options) : base(options)
        {
        }

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);
        }
    }
}" > ${name}DbContext.cs

cd ..

# BLL
dotnet new classlib -n $name.BLL
cd $name.BLL
dotnet add reference ../$name.Models/$name.Models.csproj
dotnet add reference ../$name.DAL/$name.DAL.csproj
rm Class1.cs
cd ..

# MVC
# if [ $withAuth == "y" ]; then
#     dotnet new mvc --auth Individual -n $name
#     # donet add package Microsoft.AspNetCore.Identity.EntityFrameworkCore 
#     # donet add package Microsoft.AspNetCore.Identity.UI
# else
#     dotnet new mvc -n $name
# fi

dotnet new mvc -n $name --use-program-main
cd $name
if [ $withAuth == "y" ]; then
    dotnet add package Microsoft.AspNetCore.Identity.EntityFrameworkCore 
    dotnet add package Microsoft.AspNetCore.Identity.UI
fi
dotnet add package Microsoft.EntityFrameworkCore
dotnet add package Microsoft.EntityFrameworkCore.SqlServer
dotnet add package Microsoft.EntityFrameworkCore.Tools
dotnet add reference ../$name.Models/$name.Models.csproj
dotnet add reference ../$name.BLL/$name.BLL.csproj
dotnet add reference ../$name.DAL/$name.DAL.csproj

echo "{
  \"ConnectionStrings\": {
    \"DefaultConnection\": \"Server=.\\\\SQLEXPRESS;Database=${database};Integrated Security=True;TrustServerCertificate=True;\"
  },
  \"Logging\": {
    \"LogLevel\": {
      \"Default\": \"Information\",
      \"Microsoft\": \"Warning\",
      \"Microsoft.Hosting.Lifetime\": \"Information\"
    }
  },
  \"AllowedHosts\": \"*\"
}" > appsettings.json

cd ..

dotnet sln add $name
dotnet sln add $name.BLL
dotnet sln add $name.DAL
dotnet sln add $name.Models
echo "Project setup complete."