#include <security/pam_appl.h>
#include <security/pam_misc.h>
#include <stdio.h>
#include <stdlib.h>

static struct pam_conv conv = {
    misc_conv,
    NULL
};

int main(int argc, char *argv[]) {
    pam_handle_t *pamh = NULL;
    int ret;
    const char *user = "nobody";

    if (argc == 2) {
        user = argv[1];
    } else if (argc > 2) {
        fprintf(stderr, "Usage: check_user [username]\n");
        exit(1);
    }

    ret = pam_start("check", user, &conv, &pamh);

    if (ret == PAM_SUCCESS) {
        ret = pam_authenticate(pamh, 0);    // Check if user is valid
    }

    if (ret == PAM_SUCCESS) {
        ret = pam_acct_mgmt(pamh, 0);       // Check if access is permitted
    }

    // Print authentication result
    if (ret == PAM_SUCCESS) {
        printf("Authenticated\n");
    } else {
        printf("Not Authenticated\n");
    }

    printf("Error code: %s\n", pam_strerror(pamh, ret));

    if (pam_end(pamh, ret) != PAM_SUCCESS) {
        pamh = NULL;
        fprintf(stderr, "check_user: Failed to release authenticator\n");
        exit(1);
    }

    return (ret == PAM_SUCCESS ? 0 : 1);    // Indicate success
}