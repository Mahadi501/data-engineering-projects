{% docs docs_stg_claims %}
### Description
Loads data from the claims object inside the bronze layer. 
Performs some column renaming which do not require any business SME input.

### Grain 
The grain for this object is: one row represents on unique claim_id. However, duplicates may exists if same files are ingested multiple times.

### Consumer
Will be used by the int_claim_master model as input

{% enddocs %}

{% docs docs_stg_payments %}
### Description
Loads data from the payments object inside the bronze layer. 
Performs some column renaming which do not require any business SME input.

### Grain 
The grain for this object is:  one row represents on unique payment_id. However, duplicates may exists if same files are ingested multiple times.

### Consumer
Will be used by the int_payment_details model as input

{% enddocs %}