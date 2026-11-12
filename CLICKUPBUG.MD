[Seller Panel] Feature Parity Bug (Contract Details Screen - Incomplete Mobile View): The mobile app's contract details view is truncated and lacks the comprehensive contract breakdowns, participant contact cards, and visual logistics route shown on the webapp. The expected result is that the mobile app should match the webapp's data completeness so sellers have full visibility on mobile.

[Seller Panel] Functional Bug (Company Branches Network Screen - Incorrect Success Toast Message on Exit/Removal): On the "Company Branches Network" screen, when a user exits or gets removed from a branch, the bottom toast notification displays a conflicting success message stating "Success: You are not added to this branch" even though the branch card is still visibly listed in the network view. The expected result is that either the toast message should accurately reflect the status (e.g., confirming removal or detachment) or the unlinked branch should immediately disappear from the active warehouse network list.


[Seller Panel] System Stability Bug (Master Data Management Screen - Unexpected "Server Not Responding" Popup Error): On the "Master Data Management" screen (under the Quality Tags tab), an unexpected modal popup appears displaying a "Server Not Responding" error ("We sincerely apologize from the Daal Setu team. Our server is currently not responding. Please try again in a few moments.") even though standard navigation was being performed. The expected result is that API requests should be optimized, error handling gracefully managed, and false-positive server downtime popups eliminated during normal screen navigation.

[Seller Panel] API Validation Bug (Master Data Management Screen - "Validation Failed" Error on Adding Tag): On the "Master Data Management" screen (under Quality Tags), when attempting to add a new tag, the system immediately triggers a red bottom toast error stating "Error: Exception: Validation failed." even when valid input is provided. The expected result is that the API endpoint and frontend form validation rules should be aligned, and valid tag creation submissions should process successfully without throwing unhandled exceptions.

[Seller Panel] API Exception Bug (Master Data Management Screen - "Server is temporarily unavailable" Error on Adding Brand): On the "Master Data Management" screen (under Brands), when attempting to add a new brand, the system triggers a red bottom toast error stating "Error: Exception: Server is temporarily unavailable (HTML response). Please try again later.". The expected result is that the backend API should correctly process brand creation requests and return a valid JSON response instead of an unhandled HTML error exception.

[Seller Panel] Functional Bug (Product Media Gallery Screen - Image and Video Files Not Opening/Loading): On the "Product Media Gallery" screen (across both Images and Videos tabs), uploaded media items fail to load or open when clicked or rendered (showing broken or unplayable states). The expected result is that tapping or viewing an image or video item should correctly preview or open the media file via its proper endpoint URL without failing.


[Seller Panel] Validation UX Bug (Product Media Gallery - Raw Exception on Media Limit Exceeded): Attempting to upload multiple images or videos triggers a raw backend toast error stating that only one file is allowed per product. The expected result is that the UI should prevent additional uploads upfront or cleanly prompt for media replacement instead of throwing unhandled exception toasts.   


[Seller Panel] State Consistency Bug (Categories Screen - Success Toast Followed by Discrepancy): On the "Categories" management screen, when adding a sub-category, the system flashes a success message, but the item state fails to reflect correctly or update the parent-child sub-category count properly in the UI. The expected result is that successfully created sub-categories must immediately synchronize with the parent category record and accurately update the UI counters without conflicting state discrepancies.


[Seller Panel] Data Sync Bug (Add Root Category Modal - "Brands not Found" Dropdown Issue): In the "Add Root Category" modal popup, the brand selection dropdown incorrectly displays an empty state warning stating "Brands not Found" even though registered brands already exist in the system. The expected result is that the category creation modal should correctly fetch and populate the existing active brands list so sellers can properly select and link them.



[Seller Panel] Validation Exception Bug (Profile/Company Settings Screen - "PAN number already exists" Exception): On the profile or company settings edit screen, when updating details and saving changes, the system triggers a top toast error stating "Error: Exception: pan_number: PAN number already exists." even when modifying existing records or entering valid credentials. The expected result is that the validation check should properly handle existing unique identifiers belonging to the current user record without throwing unhandled database duplication exceptions.

[Seller Panel] Functional Bug (Seller Profile Screen - Document Download Failure): On the "Seller Profile" screen under the "Documents" section, clicking the download action button for verified documents (such as the PAN Card or GST Certificate) fails to download or open the file. The expected result is that tapping the download button should successfully initiate and complete the file download or open the document preview via its correct media endpoint.

[Seller Panel] Cross-Platform Feature Parity Bug (Sub Admins Creation Screen - Missing Role Selection/Creation Option in Mobile App): On the mobile app's "Sub Admins" creation/management interface, the form lacks the required input field or option to select or create a role for the sub-admin, which is a mandatory prerequisite step during sub-admin creation. The expected result is that the mobile app should achieve feature parity with the webapp by including a role selection dropdown or role creation option in the sub-admin form.
## Resolution status (2026-10-09)

| # | Area | Status | Resolution |
|---|---|---|---|
| 1 | Contract details mobile parity | DONE | Mobile now consumes the web contract-detail projection and shows deal, parties, contacts, packing, trade value and pickup/delivery route. |
| 2 | Branch exit/removal state | DONE | Approved membership is cancelled with the assignment, non-success results no longer show success, and the app refreshes/removes the card. |
| 3 | False server popup in Master Data | DONE | Master lookups use valid endpoints with silent fallback handling; an empty response is treated as a valid empty state. |
| 4 | Add Quality Tag validation | DONE | Tag creation now posts `tag_name` to `/api/tags/`. |
| 5 | Add Brand HTML/server error | DONE | Brand creation now posts `brand_name` to `/api/brands/`; the invalid HTML fallback endpoint was removed. |
| 6 | Product media preview | DONE | Images and videos use authenticated preview widgets and open on tap. |
| 7 | Product media limit UX | DONE | The app blocks a second upload up front and explains how to replace the existing media. |
| 8 | Category/sub-category stale state | DONE | Pending categories are returned in the tree and create/update waits for dashboard/tree refresh before showing completion. |
| 9 | Root-category brand list | DONE | Active brands use the canonical dropdown response parser with loading, retry and clean empty states. |
| 10 | Existing PAN rejected on profile edit | DONE | Unchanged PAN/GST values are not resubmitted; backend owner-aware validation was verified. |
| 11 | Profile document view/download | DONE | Documents are fetched with the auth token, saved locally and opened through the device viewer. |
| 12 | Sub-admin role selection | DONE | Mobile sub-admin form includes required multi-role selection backed by web-parity role options; API flow test passes. |

Validation: Django system check passed; six targeted backend/API tests passed across the initial run plus the isolated contract retest; targeted Flutter analyzer reported no compile errors (legacy warnings remain).
