/*---------------------------------------------------------------------------------------------
 *  Copyright (c) Microsoft Corporation. All rights reserved.
 *  Licensed under the MIT License. See License.txt in the project root for license information.
 *--------------------------------------------------------------------------------------------*/

// CUSTOM: Todo el contenido de Chat Sessions está completamente deshabilitado
import './media/chatSessions.css';
import { Disposable } from '../../../../base/common/lifecycle.js';
import { IConfigurationService } from '../../../../platform/configuration/common/configuration.js';
import { IInstantiationService } from '../../../../platform/instantiation/common/instantiation.js';
import { IWorkbenchContribution } from '../../../common/contributions.js';
import { IChatSessionsService, IChatSessionItem, ChatSessionStatus } from '../common/chatSessionsService.js';
import { EditorInput } from '../../../common/editor/editorInput.js';
import { IEditorGroup } from '../../../services/editor/common/editorGroupsService.js';
import { IChatWidget } from './chat.js';

export const VIEWLET_ID = 'workbench.view.chat.sessions';

// CUSTOM: Interfaz exportada para evitar errores de importación en otros archivos
export interface ILocalChatSessionItem extends IChatSessionItem {
	editor?: EditorInput;
	group?: IEditorGroup;
	widget?: IChatWidget;
	sessionType: 'editor' | 'widget';
	description?: string;
	status?: ChatSessionStatus;
}

// CUSTOM: Clase mínima para evitar errores de registro, pero sin funcionalidad
export class ChatSessionsView extends Disposable implements IWorkbenchContribution {
	static readonly ID = 'workbench.contrib.chatSessions';

	constructor(
		@IConfigurationService _configurationService: IConfigurationService,
		@IInstantiationService _instantiationService: IInstantiationService,
		@IChatSessionsService _chatSessionsService: IChatSessionsService,
	) {
		super();
		// No-op: Chat Sessions completamente deshabilitado
	}
}

// CUSTOM: Todo el resto del código original está deshabilitado
/*
[Contenido original del archivo comentado para referencia]

NOTA: Este archivo ha sido completamente deshabilitado como parte de la customización
para eliminar la funcionalidad de Chat/Copilot Sessions del proyecto.

Si necesitas restaurar la funcionalidad original, recupera el contenido desde el
control de versiones.
*/
