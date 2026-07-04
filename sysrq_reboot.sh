# Perform a Magic SysRq reboot if hung processes or stuck NTFS operations prevent a normal reboot.
# Because I'm too lazy to reformat the NTFS drive and re-download all my games.

# Return 1 - Error: Insufficient Root privileges
# Return 2 - Error writing 's' to /proc/sysrq-trigger 
# Return 3 - Error writing 'u' to /proc/sysrq-trigger 
# Return 4 - Error writing 'b' to /proc/sysrq-trigger 
# Return 5 - Error writing to /proc/sysrq-trigger - code unknown 


check_root(){

    if (( EUID != 0 )); then

        \printf "\n[ERROR] This script must be run as root.\n\n"
        return 1
        
    fi

}


write_to_sysrq_trigger(){

    
    #- Do errors manually to capture where it failed actually

    \printf "\n[INFO] Writing to /proc/sysrq-trigger...\n"

    # Syncs those filthy buffers to disk.
    \printf "s" > /proc/sysrq-trigger || return 2

    # Give the kernel a moment to finish flushing.
    sleep 10

    # Remount all filesystems read-only.
    \printf "u" > /proc/sysrq-trigger || return 3

    # Immediately reboot.
    \printf "b" > /proc/sysrq-trigger || return 4


}



reboot_system_normally(){


    #- If the above fails, just default to a normal reboot - gonna have to reboot anyways so....
    #- I will use shutdown -r now instead of reboot just for clearer warnings.

    \shutdown -r now || {

        local return_code=$?

        \printf "\n[ERROR] The reboot command failed!\n"
        \printf "[RETURN] Code: %d on command 'shutdown -r now'\n" "$return_code"

        return "$return_code"
    }

    return 0

}




sysrq_reboot_main(){

    check_root || return $?

    write_to_sysrq_trigger || {

        local return_code=$?

        \printf "\n[ERROR] Magic SysRq sequence failed.\n"

        case "$return_code" in
           
            2)
                
                \printf "\n[FAILED] Could not write 's' (sync) to /proc/sysrq-trigger.\n"
            
            ;;

            3)
                
                \printf "\n[FAILED] Could not write 'u' (remount read-only) to /proc/sysrq-trigger.\n"

            ;;

            4)
                \printf "\n[FAILED] Could not write 'b' (reboot) to /proc/sysrq-trigger.\n"

            ;;

            *)
                
                \printf "\n[FAILED] Unknown error code!\n"
                return 5

            ;;

        esac


        \printf "\n[WARNING] Falling back to a normal reboot in 10 seconds.\n"
        \printf "[INFO] Press Ctrl+C now to cancel.\n"

        sleep 10


        reboot_system_normally


        return "$return_code"

    }


    return 0


}



sysrq_reboot_main