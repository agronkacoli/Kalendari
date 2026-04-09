/**
 * Google Apps Script backend për WebApp-in e famullisë.
 *
 * 1) Krijo Google Sheet me fletët:
 *    - Households: id | headName | phone | email | address
 *    - Members: id | familyId | fullName | role | birthDate | gender | notes
 *    - Sacraments: id | memberId | type | date | place | priest | notes
 * 2) Vendos ID e sheet-it te SPREADSHEET_ID.
 * 3) Deploy si Web App (Execute as: Me, Who has access: Anyone with the link).
 */

const SPREADSHEET_ID = 'VENDOS_ID_E_GOOGLE_SHEET_KETU';

function doGet(e) {
  const action = (e.parameter.action || '').trim();

  switch (action) {
    case 'listHouseholds':
      return jsonResponse(readAll('Households'));
    case 'listMembers':
      return jsonResponse(readAll('Members'));
    case 'listSacraments':
      return jsonResponse(readAll('Sacraments'));
    default:
      return jsonResponse({
        ok: false,
        message: 'Action i panjohur.',
        allowed: ['listHouseholds', 'listMembers', 'listSacraments']
      });
  }
}

function doPost(e) {
  const action = (e.parameter.action || '').trim();
  const payload = parseBody_(e.postData && e.postData.contents);

  switch (action) {
    case 'upsertHousehold':
      return jsonResponse(upsertById('Households', payload));
    case 'deleteHousehold':
      return jsonResponse(deleteById('Households', payload.id));
    case 'upsertMember':
      return jsonResponse(upsertById('Members', payload));
    case 'deleteMember':
      return jsonResponse(deleteById('Members', payload.id));
    case 'upsertSacrament':
      return jsonResponse(upsertById('Sacraments', payload));
    case 'deleteSacrament':
      return jsonResponse(deleteById('Sacraments', payload.id));
    default:
      return jsonResponse({ ok: false, message: 'Action i panjohur.' });
  }
}

function getSheet_(sheetName) {
  return SpreadsheetApp.openById(SPREADSHEET_ID).getSheetByName(sheetName);
}

function readAll(sheetName) {
  const sheet = getSheet_(sheetName);
  const values = sheet.getDataRange().getValues();
  if (values.length < 2) return [];

  const headers = values[0];
  return values.slice(1).filter(row => row[0] !== '').map((row) => {
    const obj = {};
    headers.forEach((h, i) => obj[h] = row[i] ?? '');
    return obj;
  });
}

function upsertById(sheetName, payload) {
  if (!payload || !payload.id) {
    return { ok: false, message: 'Fusha id është e detyrueshme.' };
  }

  const sheet = getSheet_(sheetName);
  const values = sheet.getDataRange().getValues();
  const headers = values[0];

  if (!headers || headers[0] !== 'id') {
    return { ok: false, message: `Header-i i parë te ${sheetName} duhet të jetë 'id'.` };
  }

  const idIndex = 0;
  let rowIndex = -1;
  for (let i = 1; i < values.length; i++) {
    if (String(values[i][idIndex]) === String(payload.id)) {
      rowIndex = i + 1;
      break;
    }
  }

  const rowData = headers.map((header) => payload[header] ?? '');

  if (rowIndex === -1) {
    sheet.appendRow(rowData);
    return { ok: true, message: 'Rresht i ri u shtua.' };
  }

  sheet.getRange(rowIndex, 1, 1, headers.length).setValues([rowData]);
  return { ok: true, message: 'Rreshti u përditësua.' };
}

function deleteById(sheetName, id) {
  if (!id) return { ok: false, message: 'ID mungon.' };

  const sheet = getSheet_(sheetName);
  const values = sheet.getDataRange().getValues();

  for (let i = 1; i < values.length; i++) {
    if (String(values[i][0]) === String(id)) {
      sheet.deleteRow(i + 1);
      return { ok: true, message: 'Rreshti u fshi.' };
    }
  }

  return { ok: false, message: 'ID nuk u gjet.' };
}

function parseBody_(raw) {
  if (!raw) return {};
  try {
    return JSON.parse(raw);
  } catch (error) {
    return {};
  }
}

function jsonResponse(data) {
  return ContentService.createTextOutput(JSON.stringify(data))
    .setMimeType(ContentService.MimeType.JSON);
}
