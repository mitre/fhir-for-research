# Setting up everything to work on the FHIR for Research website for windows

1.  Go to github.com and sign up for an account, enable 2fa, get added to relevant repo(s)
2.  Go to quarto.org and go to "get started", and download quarto
3.  Install R using this website: <https://cran.r-project.org/bin/macosx/>
4.  Install RStudio: <https://posit.co/download/rstudio-desktop/> should auto-populate with appropriate version for Mac
5.  Install Git using this website: <https://git-scm.com/download/mac>

-   Double check that you have Git installed by typing Git in terminal or command prompt. Doing so should produce options and recommendations for git commands

6.  SSL Issues---this may be an issue for MITRE-employees using ZScaler.

-   Download MITRE cert and save in home file
-   Paste the following in terminal, replacing <username> with your own:

```         
git config --global http.sslCAInfo
C:/Users/<username> /ca-certificates.crt
```

7.  Install Python for Mac:
    -   Go to <https://www.python.org/downloads/macos/> and select the latest version to install
    -   Scroll down and select the macOS file version to download
    -   Follow installation instructions
    -   Check to make sure Python is installed with the following command: `python --version`
8.  Open RStudio

-   Load the project in RStudio
    -   Either navigate through the file navigator on the right if you have the project locally, or if you need to clone an existing, remote repository, use the instructions here: <https://happygitwithr.com/rstudio-git-github.html>
-   Copy/Paste the following command into Console if prompted with an error:

```         
renv::restore()
```

-   Copy/paste the following into Console if prompted:

```         
renv::snapshot()
```

9.  Install Jupyter using the instructions at <https://jupyter.org/install>

-   To check that Jupyter is installed correctly, copy/paste the following command into terminal or command prompt. It should launch Jupyter Notebook: `jupyter notebook`

-   Resources that might be helpful:

    -   <https://jupyter-notebook.readthedocs.io/en/stable/troubleshooting.html>
    -   <https://stackoverflow.com/questions/48350692/jupyter-notebook-installation-issue-using-pip>
    -   <https://www.geeksforgeeks.org/how-to-setup-anaconda-path-to-environment-variable/>

10. Useful to know:

-   `quarto check` in the terminal or command prompt will return what components of Quarto have been installed properly and where there might be issues