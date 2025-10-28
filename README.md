# Smart command not found 
## **Why**

I wrote this plug in out of frustration from how the [command-not-found](https://github.com/ohmyzsh/ohmyzsh/blob/master/plugins/command-not-found/command-not-found.plugin.zsh)  plugin provided by OMZ only displays Homebrew available packages

## **What does it do**

I wanted a plugin that shows me all the available options when a command is not found, so I included many package manager to check from so the plugin can work on multiple systems

> [!NOTE]
> If you didn't find a packager manager you are looking for please inform me or add it yourself and submit a pull request

## **How to get it**

1.  make sure you have [_Oh My Zh_](https://ohmyz.sh/) installed 
    1.  install [fzf](https://junegunn.github.io/fzf/installation/)(optional)
2.  clone the repository
    
    ```sh
    git clone https://github.com/rami-shalhoub/Smart-command-not-found.git ~/.oh-my-zsh/custom/plugins/
    ```
3.  add “smart-command-not-found” to the plugins array in `~/.zshrc`
    
    ```plain
    plugins=(... smart-command-not-found ...)
    ```

## **How it looks**

<figure class="image image_resized image-style-block-align-left" style="width:45.79%;"><img style="aspect-ratio:854/413;" src="./pictures/Smart command not found_Sc.png" width="854" height="413"></figure>

<img src="./pictures/1_Smart command not found_Sc.png" width="2000" height="681">
