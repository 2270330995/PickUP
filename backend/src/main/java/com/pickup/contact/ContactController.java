package com.pickup.contact;

import com.pickup.common.api.ApiResponse;
import com.pickup.contact.dto.ContactResponse;
import com.pickup.contact.dto.CreateContactRequest;
import com.pickup.contact.dto.UpdateContactRequest;
import com.pickup.security.CurrentUser;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.UUID;

/** Organizer-owned reusable People roster (Phase 4D-1). */
@RestController
@RequestMapping("/api/v1/contacts")
public class ContactController {

    private final ContactService contactService;

    public ContactController(ContactService contactService) {
        this.contactService = contactService;
    }

    @GetMapping
    public ApiResponse<List<ContactResponse>> list() {
        return ApiResponse.ok(contactService.listContacts(CurrentUser.require().getId()));
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public ApiResponse<ContactResponse> create(@Valid @RequestBody CreateContactRequest request) {
        return ApiResponse.ok(contactService.createContact(CurrentUser.require().getId(), request));
    }

    @GetMapping("/{id}")
    public ApiResponse<ContactResponse> get(@PathVariable UUID id) {
        return ApiResponse.ok(contactService.getContact(CurrentUser.require().getId(), id));
    }

    @PatchMapping("/{id}")
    public ApiResponse<ContactResponse> update(@PathVariable UUID id,
                                               @Valid @RequestBody UpdateContactRequest request) {
        return ApiResponse.ok(contactService.updateContact(CurrentUser.require().getId(), id, request));
    }

    /** Soft-archive: contacts referenced by historical events are never hard-deleted. */
    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void archive(@PathVariable UUID id) {
        contactService.archiveContact(CurrentUser.require().getId(), id);
    }
}
