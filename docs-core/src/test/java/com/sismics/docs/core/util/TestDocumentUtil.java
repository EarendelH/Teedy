package com.sismics.docs.core.util;

import com.sismics.docs.BaseTransactionalTest;
import com.sismics.docs.core.constant.PermType;
import com.sismics.docs.core.dao.AclDao;
import com.sismics.docs.core.dao.DocumentDao;
import com.sismics.docs.core.dao.dto.AclDto;
import com.sismics.docs.core.model.jpa.Document;
import com.sismics.docs.core.model.jpa.User;
import org.junit.Assert;
import org.junit.Test;

import java.util.Date;
import java.util.List;

/**
 * Test of the DocumentUtil class.
 *
 * @author bgamard
 */
public class TestDocumentUtil extends BaseTransactionalTest {

    @Test
    public void testCreateDocument() throws Exception {
        // Create a user
        User user = createUser("testuser");

        // Create a document
        Document document = new Document();
        document.setUserId(user.getId());
        document.setTitle("Test Document");
        document.setDescription("This is a test document");
        document.setLanguage("eng");
        document.setCreateDate(new Date());

        // Call the method under test
        DocumentUtil.createDocument(document, user.getId());

        // The document ID should be set after creation by the DAO
        String documentId = document.getId();
        Assert.assertNotNull("Document ID should be set after creation", documentId);

        // Verify the document exists in the database
        DocumentDao documentDao = new DocumentDao();
        Document dbDocument = documentDao.getById(documentId);
        Assert.assertNotNull("Document should exist in database", dbDocument);
        Assert.assertEquals("Test Document", dbDocument.getTitle());

        // Verify ACLs were created
        AclDao aclDao = new AclDao();
        List<AclDto> acls = aclDao.getBySourceId(documentId, null);
        Assert.assertNotNull(acls);
        Assert.assertTrue("Should have at least 2 ACLs (READ and WRITE)", acls.size() >= 2);

        // Verify READ and WRITE ACLs exist
        boolean hasReadAcl = false;
        boolean hasWriteAcl = false;

        for (AclDto acl : acls) {
            if (acl.getTargetId().equals(user.getId())) {
                if (acl.getPerm() == PermType.READ) {
                    hasReadAcl = true;
                } else if (acl.getPerm() == PermType.WRITE) {
                    hasWriteAcl = true;
                }
            }
        }

        Assert.assertTrue("READ ACL should be created for user", hasReadAcl);
        Assert.assertTrue("WRITE ACL should be created for user", hasWriteAcl);
    }

    @Test
    public void testCreateDocumentWithMinimalData() throws Exception {
        // Create a user
        User user = createUser("testuser2");

        // Create a document with minimal data
        Document document = new Document();
        document.setUserId(user.getId());
        document.setTitle("Minimal Doc");
        document.setLanguage("eng");
        document.setCreateDate(new Date());

        // Call the method under test
        DocumentUtil.createDocument(document, user.getId());

        // Verify the document ID was set
        Assert.assertNotNull("Document ID should be set", document.getId());

        // Verify ACLs were created
        AclDao aclDao = new AclDao();
        List<AclDto> acls = aclDao.getBySourceId(document.getId(), null);
        Assert.assertTrue("Should have at least 2 ACLs", acls.size() >= 2);
    }
}
